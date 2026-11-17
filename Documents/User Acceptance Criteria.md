# User Acceptance Criteria

## Home Screen

1. The home page shows exactly the 5 products the admin marked as top rated. Nothing else appears in this section.
2. Each featured product card shows its image, name, price, and rating.
3. Tapping a featured card opens that product's detail page.
4. The 5 cards display in the same order for every customer.
5. The section fits the mobile screen width. Cards scroll horizontally or stack, with no sideways page scroll.
6. Images load with a placeholder while loading, and show a fallback image if they fail.
7. If the featured data can't load, the section is hidden or shows a retry message, and the rest of the home page still works.
8. A featured product that is out of stock or unavailable shows a clear label, and the customer can still tap it to view details.
9. The section is visible without any login, and no sign-in is needed to see it.
10. Featured products look the same whether the customer is signed in or not.
11. Network failure is handled: the customer sees a clear message and a retry option, and the rest of the home page still works.
12. API failure is handled: the customer sees a clear message and a retry option, and the rest of the home page still works.
13. Pull to refresh reloads the featured section and shows the latest top rated products.

## Category Section at Home

1. The Categories section sits at the end of Home, after the Top rated row and above the tab bar.
2. It shows every category the backend returns. The app does not keep its own fixed list.
3. Categories appear in the order the backend sends them.
4. Each category shows its name and a tile or image.
5. Tapping a category opens that category's Category page.
6. Categories are laid out in a grid (2 or 3 columns at phone width) that wraps onto new rows. There is no sideways scrolling.
7. The section scrolls with the rest of Home.
8. While categories load, the section shows placeholder tiles.
9. If the backend returns no categories, the whole section is hidden.

## Search

1. Results update as the customer types. No button tap is needed.
2. The request starts 300 ms after the last keystroke (debounce). Typing updates the field immediately, but no request is sent for each character.
3. Searching starts at 2 characters. Under 2 characters, the results show the default view (recent searches on Home, the category's products on a Category page).
4. The search button and the Return key do not trigger a new search. They dismiss the keyboard and keep the current results.
5. On Home, the search covers the whole catalogue. On a Category page, it covers only that category.
6. Leading and trailing spaces are trimmed, and matching is case-insensitive.
7. If the trimmed query is the same as the last one searched, no new request is sent.
8. When the text changes, the previous in-flight request is cancelled before the new one starts.
9. Each response is matched to the query that started it. A late response for an old query is discarded.
10. Only the latest query's results are shown.
11. The query is URL-encoded, so symbols, accents and emoji do not break the request.
12. Input is limited to 100 characters.
13. While a request is running, a small loading indicator shows in the results area. The field stays usable and the previous results stay visible until the new ones arrive.
14. No matches shows "No products match '[term]'" with a hint to check the spelling or use fewer words.
15. A failed request shows a message with a retry option. The typed text is kept.
16. With no network, the message says so. The typed text is kept, and the search runs again when the connection returns.
17. Results load in pages as the customer scrolls. The app does not load every match at once.
18. Only products whose text matches the query are shown.
19. The clear button empties the field and returns to the default view.
20. The keyboard closes when the customer scrolls the results.
21. The keyboard uses the "Search" return key label, with auto-capitalisation off.
22. Recent searches are stored on the device, up to 5, with a clear option.
23. The query stays in the field when the customer opens a product and comes back.
24. Cancel closes the search and returns to the previous screen state.
25. The field has a label, such as "Search products", for VoiceOver and TalkBack.
26. The result count is announced when the results change. Announcements are throttled, so each keystroke does not trigger one.
27. Touch targets are at least 44 pt, and the field supports larger text sizes.
28. Search works without sign-in and gives the same results signed in or signed out.
29. A product matches when the query appears in its title or its description. The category name is not searched.
30. Results are ordered by rating, best rated first, with the most-rated product first when ratings are equal.
31. A search is saved to recent searches when the customer presses the Search key on the keyboard. Searches shorter than 2 characters are not saved.
32. Results are returned in pages of 20. The next page loads when the last result on screen appears.
33. The result count is announced at most once every second.

## Product page

1. Tapping a product tile on Home, Category, or Search opens the Product page.
2. The page opens with the product's name, first image, price, and rating visible without scrolling.
3. Back returns to the screen the customer came from, at the same scroll position and with the same search text.
4. The customer can swipe back from the left edge, as on other iOS screens, and use the Android back gesture.
5. The page shows the product name, price, rating with review count, stock status, and description.
6. The image gallery is swipeable, with a page indicator. Each image can be zoomed by pinch.
7. The price shows the currency and any discount, with the original price struck through.
8. Long names and descriptions wrap. They are never cut off.
9. The description can be expanded when it is longer than a few lines.
10. Stock status is clear: "In stock", "Low stock", or "Out of stock", with text as well as colour.
11. Out-of-stock products still show full details. They are not hidden or removed.
12. Product specifications appear in a readable list, with long values wrapping.
13. Reviews show a summary (average and count), with the full list loaded on demand.
14. While the product loads, the layout shows placeholders in the same positions as the real content.
15. If the product cannot be found, the page says so and offers a way back. It does not show a blank screen.
16. A failed request shows a message with a retry option.
17. With no network, the message says so. Content already loaded stays on screen.
18. Images load with a placeholder and fall back to a default image if they fail.
19. The layout fits the phone width. There is no sideways scrolling, and text stays readable at larger text sizes.
20. Touch targets, such as gallery dots and expand controls, are at least 44 pt.
21. The page scrolls smoothly. The gallery does not block vertical scrolling.
22. Dark mode keeps text, prices, and stock labels readable.
23. The page works in portrait and landscape.
24. The product page is visible without sign-in and looks the same signed in or signed out.
25. VoiceOver and TalkBack read the name, price, rating, and stock status in a sensible order.
26. Each gallery image has a text description for screen readers.
27. Share, when used, opens the system share sheet with the product name and link.

## Enquiry

1. The Enquire button is on the Product page and is visible without scrolling.
2. Tapping Enquire opens the Enquiry page for that product. The product name is shown at the top so the customer knows what they are enquiring about.
3. The enquiry is linked to the product ID, so the sales email includes the product name and link.
4. The customer can open the form without signing in.
5. Required fields are name, email, and message. Phone is optional, but if entered it must be valid.
6. Each field has a visible label. Placeholder text is not used as the label.
7. Email is validated with the app's strict email validator, not a simple "contains @" check.
8. Phone is validated as exactly 10 digits after formatting characters are removed.
9. Validation runs when the customer leaves a field, and again when they submit. Errors are shown under the field in text, not only in colour.
10. The Submit button is disabled until the required fields are valid.
11. When the customer submits with errors, the screen scrolls to the first error and focuses that field.
12. The message field accepts a set maximum length (for example 1,000 characters), with a counter shown near the limit.
13. Leading and trailing spaces are trimmed before validation and sending.
14. Each field uses the right keyboard: email for email, phone pad for phone, and standard text for name and message.
15. Pressing Return moves to the next field. Pressing Return in the last field does not submit by accident.
16. The keyboard does not hide the field the customer is typing in or the Submit button.
17. Autocorrect and auto-capitalisation are set sensibly for each field (no autocorrect on email).
18. Tapping Submit shows a loading state on the button, and the button cannot be tapped again until the request ends.
19. A successful submit shows the "Thank you" message on screen, and the sales inbox receives the email.
20. After a successful submit, the form clears and cannot be sent again from the same screen by accident.
21. A failed submit shows a clear message and keeps everything the customer typed.
22. With no network, the message says so, and the typed content is kept.
23. The customer can retry without re-entering their details.
24. If the customer has typed something and taps back or cancel, they are asked to confirm before losing the text.
25. After the thank-you message, the customer can return to the product page.
26. The form shows a short privacy notice and a link to the privacy policy.
27. If marketing consent is included, it is an unticked checkbox that the customer chooses. It is not pre-ticked.
28. The form fits the phone width, with no sideways scrolling, and text stays readable at larger text sizes.
29. Touch targets, including the Submit button and checkbox, are at least 44 pt.
30. VoiceOver and TalkBack read each field's label, the required status, and any error message.
31. Error and success messages are announced to screen readers.
32. Dark mode keeps text, field borders, and error states readable.
33. The form works in portrait and landscape.
