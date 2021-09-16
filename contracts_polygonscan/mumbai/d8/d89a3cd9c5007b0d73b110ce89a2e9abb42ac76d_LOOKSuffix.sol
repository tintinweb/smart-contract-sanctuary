/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

pragma solidity ^0.8.0;
library LOOKSuffix{
    function socksSuffixCommon() public pure returns (string[3] memory) {
            return [
                "Casual Socks",
                 "Sport Socks",
                "Grip Socks"
            ];
    }

    function socksSuffixSemirare() public pure returns (string[3] memory) {
            return [
                "Winter Socks",
                "Crew Length Socks",
                "Split Toe Socks"
            ];
    }

    function socksSuffixExclusive() public pure returns (string[3] memory) {
            return  [
                "Dress Socks",
                "Novelty Print Socks",
                "Knee High Socks"
            ];
    }

    function sunglassSuffixCommon() public pure returns (string[4] memory) {
            return [
                "Round Sunglasses",
                "Square Sunglasses",
                "Semi-Rimless Sunglasses",
                "Browline Sunglasses"
            ];
    }

    function sunglassSuffixSemirare() public pure returns (string[4] memory) {
            return [
                "Keyhole Bridge Sunglasses",
                "Brow Bar Sunglasses",
                "Wayfarer Sunglasses",
                "Club Master Sunglasses"
            ];
    }

    function sunglassSuffixExclusive() public pure returns (string[4] memory) {
            return [
                "Cat Eye Sunglasses",
                "Aviator Sunglasses",
                "Retro Square Sunglasses",
                "3D Glasses"
            ];
    }

    function shoeSuffixCommon() public pure returns (string[8] memory) {
            return [
                "Sandals",
                "High Top Sneakers",
                "Wedge Sneakers",
                "Gladiators",
                "Gum Shoes",
                "Army Boots",
                "Mary Jane Shoes",
                "Combat Boots"
            ];
    }

    function shoeSuffixSemirare() public pure returns (string[9] memory) {
            return [
                "Stiletto",
                "Platforms",
                "Slip Ons",
                "Peep Toe",
                "Ankle Strap",
                "Flats",
                "Ballerina Slippers",
                "Hiking Boots",
                "Buck Shoes"
            ];
    }

    function shoeSuffixExclusive() public pure returns (string[7] memory) {
            return [
                "Loafers",
                "Boat Shoes",
                "Brogue Shoes",
                "Snow Boots",
                "High Boots",
                "Oxfords",
                "Ankle Boots"
            ];
    }

    function accessorySuffixCommon() public pure returns (string[18] memory) {
            return [
                "Clip-on Earrings",
                "Jacket Earrings",
                "Festoon",
                "Negligee",
                "Cartilage Earrings",
                "Snap Belt",
                "Reversible Belt",
                "Athletic Belt",
                "Apron Necktie",
                "Ascot Tie",
                "Clip-on Tie",
                "Bolo/Bola Tie",
                "Cravat Necktie",
                "Sailor Tie",
                "String Tie",
                "Ribbon Sash",
                "Bullet Back Cufflink",
                "Whale Back Cufflink"
            ];
    }

    function accessorySuffixSemirare() public pure returns (string[17] memory) {
            return [
                "Mismatched Earrings",
                "Drop Earrings",
                "Teardrop Earrings",
                "Tassel Earrings",
                "Military Belt",
                "Leather Belt",
                "Metallic Belt",
                "Woven Belt",
                "Wide Belt",
                "Elastic Belt",
                "Sash Belt",
                "Corset Belt",
                "Studded Belt",
                "Cutout Gloves",
                "Cutout Mittens",
                "Fixed Back Cufflink",
                "Chain Link Cufflink"
            ];
    }

    function accessorySuffixExclusive() public pure returns (string[29] memory) {
            return [
                "Zipper Gloves",
                "Fine Textured Mittens",
                "Fur Lined Mittens",
                "Evening Gloves",
                "Gauntlet Gloves",
                "Lace Gloves",
                "Lace Mittens",
                "Ball Return Cufflink",
                "Locking Dual Action Cufflink",
                "Knotted Cufflink",
                "Faux Leather",
                "Dress Belt",
                "Casual Belt",
                "Braided Belt",
                "7-Fold Tie",
                "Bowtie",
                "Kipper Tie",
                "Skinny Tie",
                "Western Bow-Tie",
                "Diamond Stud Earrings",
                "Pearl Earrings",
                "Hoop Earrings",
                "Chandelier Earrings",
                "Ear Cuff Earrings",
                "Ball Earrings",
                "Streamlined Hoops",
                "Pendant Necklace",
                "Collar Necklace",
                "Multi-Charmed Bracelet"
            ];
    }

    function swimmerSuffixCommon() public pure returns (string[3] memory) {
            return [
                "Front Tie Bikini Top",
                "Tori Bandeau Bikini Top",
                "Swim Briefs"
            ];
    }

    function swimmerSuffixSemirare() public pure returns (string[3] memory) {
            return [
                "Square Cut Board Shorts",
                "Crinkle Frill Bottom",
                "Terracotta One Piece"
            ];
    }

    function swimmerSuffixExclusive() public pure returns (string[4] memory) {
            return [
                "Mesh Rhinestone Swimwear",
                "Knotted-Front Swim Crop Top",
                "Mesh Bikini Top",
                "Steamer Wetsuit"
            ];
    }

    function outfitSuffixCommon() public pure returns (string[24] memory) {
            return [
                "Aline Dress",
                "Tent Dress",
                "Yoke Dress",
                "Shift Dress",
                "Dirndl Dress",
                "Tunic Dress",
                "Blouson Dress",
                "Shirtwaist Dress",
                "Wrap around Dress",
                "Baby doll Dress",
                "Body con Dress",
                "Cocktail Dress",
                "Debutante Dress",
                "Skater Dress",
                "Camisole Dress",
                "Pinafore Dress",
                "Harem Dress",
                "Apron Dress",
                "Patch Pocket Suit",
                "Flap Pocket Suit",
                "Jetted Pocket Suit",
                "Basic Overalls",
                "Old Fashioned Overalls",
                "Casual Overalls"
            ];
    }

    function outfitSuffixSemirare() public pure returns (string[24] memory) {
            return [
                "Sweater Dress",
                "Swing Dress",
                "Tutu Dress",
                "Sun Dress",
                "Little Black Dress",
                "Coat Dress",
                "Corset Dress",
                "Balloon Dress",
                "Bouffant Dress",
                "Paneled Dress",
                "Handkerchief Hem Dress",
                "Gathered Dress",
                "Kaftan Dress",
                "Pillowcase Dress",
                "Slip Dress",
                "Shirt Dress",
                "Ball Gown",
                "Party Dress",
                "Single Vent Suit",
                "Double Vent Suit",
                "No Vent Suit",
                "One-Button Suit",
                "Two-Button Suit",
                "Three-Button Suit"
            ];
    }

    function outfitSuffixExclusive() public pure returns (string[21] memory) {
            return [
                "Off Shoulder Dress",
                "One Shoulder Dress",
                "Strapless Dress",
                "Halterneck Dress",
                "Draped Dress",
                "Xray Dress",
                "Fit and Flare Dress",
                "Cape Dress",
                "Sheath Dress",
                "Slim Fit Suit",
                "Classic Fit Suit",
                "Modern Fit Suit",
                "Notch Lapel Suit",
                "Shawl Lapel Suit",
                "Peak Lapel Suit",
                "Single Breasted Suit",
                "Double Breasted Suit",
                "American Cut Suit",
                "British Cut Suit",
                "Italian Cut Suit",
                "Tuxedo"
            ];
    }

    function topBottomSuffixCommon() public pure returns (string[19] memory) {
            return [
                "Jersey shirt",
                "Night Shirt",
                "Western shirt",
                "Polo shirts",
                "Sweatshirt",
                "T-shirt",
                "Tunic shirt",
                "Tuxedo shirt",
                "Undershirt",
                "Chinos",
                "Cords",
                "Drawstring Trousers",
                "Slim-Fit Trousers",
                "Wool Trousers",
                "Relaxed Leg Trousers",
                "Cropped Trousers",
                "Cargo Pants",
                "Pleated Trousers",
                "Tracksuit Bottoms"
            ];
    }

    function topBottomSuffixSemirare() public pure returns (string[19] memory) {
            return [
                "Aloha Shirt",
                "Baseball Shirt",
                "Camp Shirt",
                "Casual Shirt",
                "Epaulette Shirt",
                "Flannel Shirt",
                "Lumberjack Shirt",
                "Golf Shirt",
                "Henley Shirt",
                "Ivy league Shirt",
                "Leggings",
                "Palazzo",
                "Pegged Pants",
                "Trousers",
                "Sailor Pants",
                "Straight Pants",
                "Stirrup Pants",
                "Stove Pipe Pants",
                "Toreador Pants"
            ];
    }

    function topBottomSuffixExclusive() public pure returns (string[19] memory) {
            return [
                "Baggy Pants",
                "Culottes",
                "Fatigue Trousers",
                "Jeans",
                "Harem Pants",
                "Hot Pants",
                "Jodhpurs",
                "Oxford Button-Down Shirt",
                "Dress Shirt",
                "Cuban Collar Shirt",
                "Overshirt",
                "Flannel Shirt",
                "Office Shirt",
                "Chambray Shirt",
                "Denim Shirt",
                "Linen Shirt",
                "Polo Shirt",
                "Unstructured Blazer",
                "Patch Pocket Blazer"
            ];
    }
}