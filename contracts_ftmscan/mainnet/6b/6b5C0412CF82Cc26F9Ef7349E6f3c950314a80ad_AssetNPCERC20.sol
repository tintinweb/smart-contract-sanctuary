/**
 *Submitted for verification at FtmScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AssetNPCERC20 {

    address public immutable assetBox; 
    uint public supplyLimit;
    uint public totalSupply;
    address public immutable token;

    address private immutable owner;

    // exchange ratio
    uint public immutable ratio;
    uint public immutable eFee;
    uint public immutable eCrossFee;

    uint public immutable transferMinimumAmount;

    constructor (address assetBox_, uint supplyLimit_, address token_, uint ratio_, uint eFee_, uint eCrossFee_, uint transferMinimumAmount_) {
        owner = msg.sender;

        assetBox = assetBox_;
        supplyLimit = supplyLimit_;
        token = token_;
        ratio = ratio_;

        eFee = eFee_;
        eCrossFee = eCrossFee_;

        transferMinimumAmount = transferMinimumAmount_;
    }

    /**
        amount: asset amount
     */
    function claim(uint8 roleIndex, uint tokenID, uint amount) external {
        require(totalSupply + amount <= supplyLimit, "Over supply limit");

        address role = IAssetBox(assetBox).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), 'Not approved');
        
        totalSupply += amount;
        uint tokenAmount = amount*1e18/ratio;
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        IAssetBox(assetBox).mint(roleIndex, tokenID, amount);
    }

    /**
        function: transfer inner-race
     */
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external {
        require(from != to);
        require(amount >= transferMinimumAmount, "Less than minimum amount");

        address role = IAssetBox(assetBox).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, from), 'Not approved');

        uint fee = amount * eFee / 100;
        IAssetBox(assetBox).transfer(roleIndex, from, to, amount-fee);
        IAssetBox(assetBox).burn(roleIndex, from, fee);
    }

    /**
        function: transfer cross-race
     */ 
    function transferCrossRace(uint8 fromRoleIndex, uint from, uint8 toRoleIndex, uint to, uint amount) external {
        require(from != to);
        require(amount >= transferMinimumAmount, "Less than minimum amount");

        address role = IAssetBox(assetBox).getRole(fromRoleIndex);
        require(_isApprovedOrOwner(role, msg.sender, from), 'Not approved or owner');

        uint fee = amount * eCrossFee / 100;
        IAssetBox(assetBox).mint(toRoleIndex, to, amount-fee);
        IAssetBox(assetBox).burn(fromRoleIndex, from, amount);
    }
    
    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }

    function withdrawal(address recipient, uint amount) external {
        require(msg.sender == owner, "Only Owner");

        IERC20(token).transfer(recipient, amount);
    }
   
}