/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


contract DefiCity is Initializable {

    enum Property {
        SuperTower, //0
        Skyscraper,
        Penthouse,
        Office,
        House,
        Garrage,
        White_Diamont, //6
        Ruby,
        Platinum,
        Gold,
        Silver,
        Bronze,
        Milky_Way, //12
        Sun,
        Jupiter,
        Mars,
        Moon,
        Earth,
        Neon_Purple, //18
        Neon_Blue,
        No_Neon
    }

    struct City {
        address owner;
        bool minted;
        Property Townhouse;
        Property Resources;
        Property Planet;
        Property Grid;
        uint256 transactionTime;
    }
    
    address public stakeAddress;
    address public feeAddress;

    uint256 public burnShare;
    uint256 public stakeShare;
    uint256 public feeShare;

    uint256 public scrollPrice;
    uint256 public scrollPriceWithLINK;

    mapping(uint256 => City) public cities;

    constructor(address _stakeAddress, address _feeAddress) {
        stakeAddress = _stakeAddress;
        feeAddress = _feeAddress;

        burnShare = 25;
        stakeShare = 50;
        feeShare = 25;
    }
    
    // should use initialize instead of constructor
    function initialize(address _stakeAddress, address _feeAddress) public initializer {
        stakeAddress = _stakeAddress;
        feeAddress = _feeAddress;
    
        burnShare = 25;
        stakeShare = 50;
        feeShare = 25;
    }

    function setShares(
        uint256 _burnShare,
        uint256 _stakeShare,
        uint256 _feeShare
    ) public {
        require(
            burnShare + stakeShare + feeShare == 100,
            "Doesn't add up to 100"
        );

        burnShare = _burnShare;
        stakeShare = _stakeShare;
        feeShare = _feeShare;
    }

    function setStakeAddress(address _stakeAddress)
        public
        returns (bool)
    {
        stakeAddress = _stakeAddress;
        return true;
    }

    function setFeeAddress(address _feeAddress)
        public
        returns (bool)
    {
        feeAddress = _feeAddress;
        return true;
    }

    function setScrollPrice(uint256 _scrollPrice)
        public
        returns (bool)
    {
        scrollPrice = _scrollPrice;
        return true;
    }

    function setScrollPriceWithLINK(uint256 _scrollPriceWithLINK)
        public
        returns (bool)
    {
        scrollPriceWithLINK = _scrollPriceWithLINK;
        return true;
    }

}