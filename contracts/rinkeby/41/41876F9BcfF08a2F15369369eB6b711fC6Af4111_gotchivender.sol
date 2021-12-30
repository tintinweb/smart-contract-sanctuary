/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Fully commented standard ERC721 Distilled from OpenZeppelin Docs
    Base for Building ERC721 by Martin McConnell
    All the utility without the fluff.
*/


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Functional {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt reenter locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}


contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance){}
    function ownerOf(uint256 tokenId) external view returns (address owner){}
    function safeTransferFrom(address from,address to,uint256 tokenId) external{}
    function transferFrom(address from, address to, uint256 tokenId) external{}
    function approve(address to, uint256 tokenId) external{}
    function getApproved(uint256 tokenId) external view returns (address operator){}
    function setApprovalForAll(address operator, bool _approved) external{}
    function isApprovedForAll(address owner, address operator) external view returns (bool){}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{}
}

// ******************************************************************************************************************************
// **************************************************  Start of Main Contract ***************************************************
// ******************************************************************************************************************************


contract gotchivender is Ownable, Functional {
    uint256 public price;
    uint256 public holderPrice;
    uint256 public discountPrice;

    bool public mintActive;
    string public name;

    ERC721 CHAMFAM;
    ERC721[] DISCOUNT;

    constructor() {
        name = "Chamagotchis";
        mintActive = false;

        //initialize discount contract
        //CHAMFAM = ERC721(0xFD3C3717164831916E6D2D7cdde9904dd793eC84); // mainnet
        CHAMFAM = ERC721(0x2CDc44651e8b2EE21021221288F52f73349127DE); // testnet


        DISCOUNT.push(ERC721(0xFD3C3717164831916E6D2D7cdde9904dd793eC84)); //chamfam added to discount
            //as an example

        price = 50 * (10 ** 15); // Replace leading value with price in finney
        holderPrice = 25 * (10 ** 15); // Replace leading value with price in finney
        discountPrice = 35 * (10 ** 15); // Replace leading value with price in finney
        
    }

    function purchase() external payable {
        uint256 cost = price;
        if (CHAMFAM.balanceOf(_msgSender()) > 0){
            cost = holderPrice;  // discount for chamfam holders
        } else if (isDiscount()){
            cost = discountPrice;
        } else {
            cost = price;
        }

        require(msg.value >= cost, "Mint: Insufficient Funds");
        require(mintActive);

        //Handle ETH transactions
        uint256 cashIn = msg.value;
        uint256 cashChange = cashIn - cost;
                
        if (cashChange > 0){
            (bool success, ) = msg.sender.call{value: cashChange}("");
            require(success, "Mint: unable to send change");
        }
    }

    function isDiscount() public view returns (bool) {
        for (uint256 i; i < DISCOUNT.length; i++){
            if (DISCOUNT[i].balanceOf(_msgSender()) > 0) {
                return true;
            }        
        }
        return false;
    }
    
    function withdraw() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        bool success;

        address dev             = payable(0x2496286BDB820d40C402802F828ae265b244188A);
        address community       = payable(0x855bFE65652868920729b9d92D8d6030D01e3bFF);
        //address chamagotchi     = payable(0x0000000000000000000000000000000000000000);


        (success, ) = dev.call{value: ((sendAmount * 5)/100)}("");
        require(success, "Txn Unsuccessful");

        (success, ) = community.call{value: ((sendAmount * 35)/100)}("");
        require(success, "Txn Unsuccessful");

        //(success, ) = chamagotchi.call{value: ((sendAmount * 60)/100)}("");
        //require(success, "Txn Unsuccessful");       
    }

    function setDiscountPrice(uint256 newPrice) external onlyOwner{
        discountPrice = newPrice;
    }

    function setHolderPrice(uint256 newPrice) external onlyOwner{
        holderPrice = newPrice;
    }

    function addDiscountContract(address NFTaddress) external onlyOwner{
        DISCOUNT.push(ERC721(NFTaddress));
    }

    function activateMint() public onlyOwner {
        mintActive = true;
    }
    
    function deactivateMint() public onlyOwner {
        mintActive = false;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    receive() external payable {}
    
    fallback() external payable {}
}