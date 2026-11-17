import Foundation

/// User-facing strings. Keys live in `Resources/Localizable.strings`.
nonisolated enum L10n {
    static let homeTitle = String(localized: "home.title")
    static let homeEmpty = String(localized: "home.empty")
    static let homeLoadFailed = String(localized: "home.load_failed")
    static let homeRetry = String(localized: "home.retry")
    static let homeCategoriesLoadFailed = String(localized: "home.categories_load_failed")
    static let homeFeaturedStale = String(localized: "home.featured_stale")
    static let ratingLabel = String(localized: "home.rating_label")
    static let outOfStock = String(localized: "product.out_of_stock")
    static let featuredScrollLeft = String(localized: "home.featured_scroll_left")
    static let featuredScrollRight = String(localized: "home.featured_scroll_right")
    static let categoriesTitle = String(localized: "home.categories_title")
    static let categoryTopRated = String(localized: "category.top_rated")
    static let categoryMore = String(localized: "category.more")
    static let categoryEmpty = String(localized: "category.empty")
    static let categoryLoadFailed = String(localized: "category.load_failed")

    static let searchPrompt = String(localized: "search.prompt")
    static let searchHint = String(localized: "search.hint")
    static let searchRecentTitle = String(localized: "search.recent_title")
    static let searchRecentClear = String(localized: "search.recent_clear")
    static let searchNoMatchesHint = String(localized: "search.no_matches_hint")
    static let searchOffline = String(localized: "search.offline")
    static let searchFailed = String(localized: "search.failed")

    static let productInStock = String(localized: "product.in_stock")
    static let productShowMore = String(localized: "product.show_more")
    static let productShowLess = String(localized: "product.show_less")
    static let productSpecifications = String(localized: "product.specifications")
    static let productSpecCategory = String(localized: "product.spec_category")
    static let productSpecId = String(localized: "product.spec_id")
    static let productSpecRating = String(localized: "product.spec_rating")
    static let productSpecAvailability = String(localized: "product.spec_availability")
    static let productReviews = String(localized: "product.reviews")
    static let productNotFound = String(localized: "product.not_found")
    static let productBack = String(localized: "product.back")
    static let productOffline = String(localized: "product.offline")
    static let productLoadFailed = String(localized: "product.load_failed")

    static let enquireButton = String(localized: "enquiry.enquire")
    static let enquiryTitle = String(localized: "enquiry.title")
    static let enquiryNameLabel = String(localized: "enquiry.name_label")
    static let enquiryEmailLabel = String(localized: "enquiry.email_label")
    static let enquiryPhoneLabel = String(localized: "enquiry.phone_label")
    static let enquiryMessageLabel = String(localized: "enquiry.message_label")
    static let enquiryMarketing = String(localized: "enquiry.marketing")
    static let enquiryPrivacy = String(localized: "enquiry.privacy")
    static let enquiryPrivacyLink = String(localized: "enquiry.privacy_link")
    static let enquirySubmit = String(localized: "enquiry.submit")
    static let enquirySentTitle = String(localized: "enquiry.sent_title")
    static let enquirySentBody = String(localized: "enquiry.sent_body")
    static let enquiryBackToProduct = String(localized: "enquiry.back_to_product")
    static let enquiryDiscardTitle = String(localized: "enquiry.discard_title")
    static let enquiryDiscard = String(localized: "enquiry.discard")
    static let enquiryKeepWriting = String(localized: "enquiry.keep_writing")
    static let enquiryCancel = String(localized: "enquiry.cancel")
    static let enquiryErrorName = String(localized: "enquiry.error_name")
    static let enquiryErrorEmail = String(localized: "enquiry.error_email")
    static let enquiryErrorPhone = String(localized: "enquiry.error_phone")
    static let enquiryErrorMessage = String(localized: "enquiry.error_message")
    static let enquiryErrorsAnnouncement = String(localized: "enquiry.errors_announcement")
    static let enquirySentAnnouncement = String(localized: "enquiry.sent_announcement")
    static let enquiryFailedAnnouncement = String(localized: "enquiry.failed_announcement")
    static let enquiryFailed = String(localized: "enquiry.failed")
    static let enquiryOffline = String(localized: "enquiry.offline")
    static let enquiryRequiredSuffix = String(localized: "enquiry.required_suffix")
    static let enquiryOptionalSuffix = String(localized: "enquiry.optional_suffix")
    static let enquiryDone = String(localized: "enquiry.done")
    static let enquiryBack = String(localized: "enquiry.back")
    static let enquiryAboutLabel = String(localized: "enquiry.about_label")
    static let enquiryQuickTitle = String(localized: "enquiry.quick_title")
    static let enquiryPromptStock = String(localized: "enquiry.prompt_stock")
    static let enquiryPromptDelivery = String(localized: "enquiry.prompt_delivery")
    static let enquiryPromptWarranty = String(localized: "enquiry.prompt_warranty")
    static let enquiryMessagePlaceholder = String(localized: "enquiry.message_placeholder")

    static func enquiryMissing(_ fields: String) -> String {
        String(format: String(localized: "enquiry.missing"), fields)
    }

    static func enquiryCounter(_ count: Int, _ limit: Int) -> String {
        String(format: String(localized: "enquiry.counter"), count, limit)
    }

    static func productImageLabel(_ name: String, _ index: Int, _ total: Int) -> String {
        String(format: String(localized: "product.image_label"), index, total, name)
    }

    static func searchNoMatches(_ term: String) -> String {
        String(format: String(localized: "search.no_matches"), term)
    }

    static func searchResultCount(_ count: Int) -> String {
        count == 1
            ? String(localized: "search.result_count_one")
            : String(format: String(localized: "search.result_count_other"), count)
    }
}
