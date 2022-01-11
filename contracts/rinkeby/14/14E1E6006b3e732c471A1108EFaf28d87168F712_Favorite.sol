//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Favorite {
    struct Image {
        uint256 imageId;
        string imageUri;
    }

    Image[] public images;
    // User => ImageId => Favorite
    mapping(address => mapping(uint256 => bool)) public favorites;

    event Mint(uint256 imageId, string imageUri);
    event Liked(uint256 imageId, address who, bool liked);

    modifier onlyValidImageId(uint256 imageId) {
        require(imageId < images.length, "Invalid image id");
        _;
    }

    function mint(string memory uri) external {
        Image storage image = images[images.length];
        image.imageId = images.length;
        image.imageUri = uri;

        emit Mint(image.imageId, image.imageUri);
    }

    function like(uint256 imageId) external onlyValidImageId(imageId) {
        require(!favorites[msg.sender][imageId], "Already liked");

        favorites[msg.sender][imageId] = true;
        emit Liked(imageId, msg.sender, true);
    }

    function unlike(uint256 imageId) external onlyValidImageId(imageId) {
        require(favorites[msg.sender][imageId], "Already unliked");

        favorites[msg.sender][imageId] = false;
        emit Liked(imageId, msg.sender, false);
    }
}