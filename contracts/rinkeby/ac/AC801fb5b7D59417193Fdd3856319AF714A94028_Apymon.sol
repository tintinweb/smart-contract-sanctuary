// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20.sol';
import './ERC721.sol';
import './Ownable.sol';

interface ERC20Interface is IERC20 {
    function deposit() external payable;
}

interface IApymonPack {
    function increaseInsideTokenBalance(
        uint256 eggId,
        uint8 tokenType,
        address token,
        uint256 amount
    ) external;
}

contract Apymon is ERC721, Ownable {
    using SafeMath for uint256;

    string public constant APYMON_PROVENANCE = "df760c771ad006eace0d705383b74158967e78c6e980b35f670249b5822c42e1";

    // Maximum amount of Eggs in existance. Ever.
    uint256 public constant MAX_EGG_SUPPLY = 6400;
    uint256 public constant MAX_APYMON_SUPPLY = 12800;
    
    // Referral management
    mapping(address => uint256) public _referralAmounts;
    mapping(address => mapping(address => bool)) public _referralStatus;

    IApymonPack public _apymonpack;

    ERC20Interface private constant _weth = ERC20Interface(
        0xc778417E063141139Fce010982780140Aa0cD5Ab
    );

    address payable private constant _team = payable(
        0x23F40f52b2171A81355eA8fea03Fa8F0FbB0Dd68
    );
    bool public hasSaleStarted = false;

    constructor(
        string memory baseURI
    ) ERC721("Apymon", "APYMON") {
        _setBaseURI(baseURI);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
    * @dev Gets egg count to mint per once.
    */
    function getMintableCount() public view returns (uint256) {
        uint256 eggSupply = totalSupply();

        if (eggSupply > MAX_EGG_SUPPLY) {
            return 0;
        } else if (eggSupply > 6395) { // 6396 ~ 6400
            return 1;
        } else if (eggSupply > 6300) { // 6301 ~ 6395
            return 5;
        } else if (eggSupply > 6000) { // 6001 ~ 6300
            return 10;
        } else {
            return 20; // 1 ~ 6000
        }
    }

    function getEggPrice() public view returns (uint256) {
        uint256 eggSupply = totalSupply();

        if (eggSupply >= MAX_EGG_SUPPLY) {
            return 0;
        } else if (eggSupply > 6395) { // 6396 ~ 6400
            return 3 ether;
        } else if (eggSupply > 6300) { // 6301 ~ 6395
            return 1 ether;
        } else if (eggSupply > 6000) { // 6001 ~ 6300
            return 0.9 ether;
        } else if (eggSupply > 5000) { // 5001 ~ 6000
            return 0.64 ether;
        } else if (eggSupply > 3000) { // 3001 ~ 5000
            return 0.32 ether;
        } else if (eggSupply > 1000) { // 1001 ~ 3000
            return 0.16 ether;
        } else {
            return 0.08 ether; // 1 ~ 1000
        }
    }

    function distributeBonus(
        uint256 startEggId,
        uint256 endEggId
    ) external onlyOwner {
        require(
            !hasSaleStarted,
            "Sale hasn't finised yet."
        );
        uint256 totalBonus;
        uint256 bonus;
        
        for (uint256 i = startEggId; i <= endEggId; i++) {
            if (i > 6395) { // 6396 ~ 6400
                bonus = 0.3 ether;
            } else if (i > 6300) { // 6301 ~ 6395
                bonus = 0.1 ether;
            } else if (i > 6000) { // 6001 ~ 6300
                bonus = 0.09 ether;
            } else if (i > 5000) { // 5001 ~ 6000
                bonus = 0.064 ether;
            } else if (i > 3000) { // 3001 ~ 5000
                bonus = 0.032 ether;
            } else if (i > 1000) { // 1001 ~ 3000
                bonus = 0.016 ether;
            } else {
                bonus = 0.008 ether; // 1 ~ 1000
            }

            _apymonpack.increaseInsideTokenBalance(
                i,
                1, // TOKEN_TYPE_ERC20
                address(_weth),
                bonus
            );

            totalBonus = totalBonus.add(bonus);
        }
        if (totalBonus > 0) {
            _weth.deposit{ value: totalBonus }();
            _weth.transfer(address(_apymonpack), totalBonus);
        }
    }

    function distributeReferral(
        uint256 startEggId,
        uint256 endEggId
    ) external onlyOwner {
        require(
            !hasSaleStarted,
            "Sale hasn't finised yet."
        );
        uint256 totalReferralAmount;

        for (uint256 i = startEggId; i <= endEggId; i++) {
            address owner = ownerOf(i);
            uint256 referralAmount = _referralAmounts[owner];
            if (referralAmount > 0) {
                _apymonpack.increaseInsideTokenBalance(
                    i,
                    1, // TOKEN_TYPE_ERC20
                    address(_weth),
                    referralAmount
                );
                totalReferralAmount = totalReferralAmount.add(referralAmount);
                delete _referralAmounts[owner];
            }
        }

        if (totalReferralAmount > 0) {
            _weth.deposit{ value: totalReferralAmount }();
            _weth.transfer(address(_apymonpack), totalReferralAmount);
        }
    }
    
    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory baseURI) onlyOwner external {
       _setBaseURI(baseURI);
    }

    /**
    * @dev Set apymon pack address
    */
    function setApymonPack(address apymonpack) onlyOwner external {
       require(
           address(_apymonpack) == address(0),
           "Setting have done already"
        );
       _apymonpack = IApymonPack(apymonpack);
    }

    /**
     * @dev Mints yourself Eggs.
     */
    function mintEggs(
        address to,
        uint256 count,
        address referee
    ) public payable {
        require(
            hasSaleStarted,
            "Sale hasn't started."
        );
        require(
            count > 0 && count <= getMintableCount()
        );
        require(
            SafeMath.add(totalSupply(), count) <= MAX_EGG_SUPPLY
        );
        require(
            SafeMath.mul(getEggPrice(), count) == msg.value
        );

        for (uint256 i; i < count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
        }

        if (referee != address(0)) {
            _addReferralAmount(referee, to, msg.value);
        }
    }

    /**
     * @dev Mints creature to apymonpacks.
     * Creatures must be distributed to owners of egg.
     */
    function mintCreatures(
        uint256 count
    ) external onlyOwner {
        require(
            count > 0 &&
            SafeMath.add(totalSupply(), count) <= MAX_APYMON_SUPPLY,
            "Invalid count to mint."
        );
        require(
            !hasSaleStarted,
            "Sale hasn't finised yet."
        );
        for (uint256 i; i < count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(address(_apymonpack), mintIndex);
        }
    }

    /**
     * @dev send eth to team and treasury.
     */
    function requestTeamFund(
        uint256 amount
    ) external onlyOwner {
        uint256 teamFund = amount.div(2);
        _team.transfer(teamFund);
        payable(msg.sender).transfer(amount.sub(teamFund));
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    /**
     * @dev private function to record referral status.
     */
    function _addReferralAmount(
        address referee,
        address referrer,
        uint256 amount
    ) private {
        uint256 refereeBalance = ERC721.balanceOf(referee);
        bool status = _referralStatus[referrer][referee];
        uint256 referralAmount = amount.div(10);

        if (refereeBalance != 0 && !status) {
            _referralAmounts[referee] = _referralAmounts[referee].add(referralAmount);
            _referralAmounts[referrer] = _referralAmounts[referrer].add(referralAmount);
            _referralStatus[referrer][referee] = true;
        }
    }
}