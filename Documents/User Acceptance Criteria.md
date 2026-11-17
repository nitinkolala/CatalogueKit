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
