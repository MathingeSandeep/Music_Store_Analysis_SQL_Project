/* Q1: Who is the senior most employee based on job title? */

SELECT *
FROM EMPLOYEE
ORDER BY LEVELS DESC
LIMIT 1;

/* Q2: Which countries have the most Invoices? */

SELECT COUNT(*) AS COUNT_OF_INVOICE,
       BILLING_COUNTRY
FROM INVOICE
GROUP BY BILLING_COUNTRY
ORDER BY COUNT_OF_INVOICE DESC;

/* Q3: What are top 3 values of total invoice? */

SELECT TOTAL
FROM INVOICE
ORDER BY TOTAL DESC
LIMIT 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals. */

SELECT BILLING_CITY,
       SUM(TOTAL) AS INVOICE_TOTAL
FROM INVOICE
GROUP BY BILLING_CITY
ORDER BY INVOICE_TOTAL DESC
LIMIT 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT CUSTOMER.CUSTOMER_ID,
       CONCAT(FIRST_NAME, '', LAST_NAME) AS FULL_NAME,
       SUM(TOTAL) AS TOTAL_SPENDING
FROM CUSTOMER
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
GROUP BY CUSTOMER.CUSTOMER_ID
ORDER BY TOTAL_SPENDING DESC
LIMIT 1;

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/* Method 1 */

SELECT DISTINCT EMAIL,
                FIRST_NAME,
                LAST_NAME,
                GENRE.NAME AS GENRENAME
FROM CUSTOMER
JOIN INVOICE ON INVOICE.CUSTOMER_ID = CUSTOMER.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE_LINE.INVOICE_ID = INVOICE.INVOICE_ID
JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
WHERE GENRE.NAME = 'Rock'
ORDER BY EMAIL;

/* Method 2 */

SELECT DISTINCT EMAIL,
                FIRST_NAME,
                LAST_NAME
FROM CUSTOMER
JOIN INVOICE ON INVOICE.CUSTOMER_ID = CUSTOMER.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE_LINE.INVOICE_ID = INVOICE.INVOICE_ID
WHERE TRACK_ID IN
    (SELECT TRACK_ID
     FROM TRACK
     JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID
     WHERE GENRE.NAME = 'Rock')
ORDER BY EMAIL;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT ARTIST.ARTIST_ID,
       ARTIST.NAME,
       COUNT(ARTIST.ARTIST_ID) AS COUNT
FROM ARTIST
JOIN ALBUM ON ARTIST.ARTIST_ID = ALBUM.ARTIST_ID
JOIN TRACK ON ALBUM.ALBUM_ID = TRACK.ALBUM_ID
JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID
WHERE GENRE.NAME = 'Rock'
GROUP BY ARTIST.ARTIST_ID,
         ARTIST.NAME
ORDER BY COUNT DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT NAME,
       MILLISECONDS
FROM TRACK
WHERE MILLISECONDS >
    (SELECT AVG(MILLISECONDS) AS AVERAGE_TRACK_LENGTH
     FROM TRACK)
ORDER BY MILLISECONDS DESC;

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customerid, customer name, artist name and total spent. */

/* Method 1 */ 

SELECT CUSTOMER.CUSTOMER_ID,
       CONCAT(FIRST_NAME, '', LAST_NAME) AS FULL_NAME,
       ARTIST.NAME,
       SUM(INVOICE_LINE.UNIT_PRICE * INVOICE_LINE.QUANTITY) AS TOTAL_AMOUNT_SPENT
FROM CUSTOMER
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
JOIN TRACK ON INVOICE_LINE.TRACK_ID = TRACK.TRACK_ID
JOIN ALBUM ON TRACK.ALBUM_ID = ALBUM.ALBUM_ID
JOIN ARTIST ON ALBUM.ARTIST_ID = ARTIST.ARTIST_ID
GROUP BY CUSTOMER.CUSTOMER_ID,
         FULL_NAME,
         ARTIST.NAME
ORDER BY TOTAL_AMOUNT_SPENT DESC;

/* Method 2 */

WITH CUSTOMER_PURCHASE AS
  (SELECT C.CUSTOMER_ID,
          CONCAT(FIRST_NAME, '', LAST_NAME) AS CUSTOMER_NAME,
          AR.ARTIST_ID,
          AR.NAME AS ARTIST_NAME,
          (IL.UNIT_PRICE * IL.QUANTITY) AS AMOUNT_SPENT
   FROM CUSTOMER C
   JOIN INVOICE I ON C.CUSTOMER_ID = I.CUSTOMER_ID
   JOIN INVOICE_LINE IL ON I.INVOICE_ID = IL.INVOICE_ID
   JOIN TRACK T ON IL.TRACK_ID = T.TRACK_ID
   JOIN ALBUM AL ON T.ALBUM_ID = AL.ALBUM_ID
   JOIN ARTIST AR ON AL.ARTIST_ID = AR.ARTIST_ID)
SELECT CUSTOMER_ID,
       CUSTOMER_NAME,
       ARTIST_NAME,
       SUM(AMOUNT_SPENT) AS TOTAL_SPENT
FROM CUSTOMER_PURCHASE
GROUP BY CUSTOMER_ID,
         CUSTOMER_NAME,
         ARTIST_NAME
ORDER BY TOTAL_SPENT DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

WITH POPULAR_GENRE AS
  (SELECT COUNT(IL.QUANTITY) AS PURCHASES,
          C.COUNTRY,
          G.NAME,
          G.GENRE_ID,
          ROW_NUMBER() OVER(PARTITION BY C.COUNTRY
                            ORDER BY COUNT(IL.QUANTITY)DESC) AS ROWNO
   FROM INVOICE_LINE IL
   JOIN INVOICE I ON IL.INVOICE_ID = I.INVOICE_ID
   JOIN CUSTOMER C ON I.CUSTOMER_ID = C.CUSTOMER_ID
   JOIN TRACK T ON IL.TRACK_ID = T.TRACK_ID
   JOIN GENRE G ON T.GENRE_ID = G.GENRE_ID
   GROUP BY C.COUNTRY,
            G.NAME,
            G.GENRE_ID
   ORDER BY C.COUNTRY,
            PURCHASES DESC)
SELECT *
FROM POPULAR_GENRE
WHERE ROWNO <= 1;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH CUSTOMER_WITH_COUNTRY AS
  (SELECT C.CUSTOMER_ID,
          CONCAT(FIRST_NAME, '', LAST_NAME) AS FULL_NAME,
          I.BILLING_COUNTRY,
          SUM(TOTAL) AS TOTAL_SPENDING,
          ROW_NUMBER() OVER(PARTITION BY I.BILLING_COUNTRY
                            ORDER BY SUM(TOTAL) DESC) AS ROWNO
   FROM INVOICE I
   JOIN CUSTOMER C ON I.CUSTOMER_ID = C.CUSTOMER_ID
   GROUP BY C.CUSTOMER_ID,
            FULL_NAME,
            I.BILLING_COUNTRY
   ORDER BY I.BILLING_COUNTRY,
            TOTAL_SPENDING DESC)
SELECT *
FROM CUSTOMER_WITH_COUNTRY
WHERE ROWNO <= 1;





