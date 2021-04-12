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

    string public APYMON_PROVENANCE = "";

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

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
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

    function getRandomNumber(uint256 a, uint256 b) public view returns (uint256) {
        uint256 min = a;
        uint256 max = (b.add(1)).sub(min);
        return (uint256(uint256(keccak256(abi.encodePacked(blockhash(block.number))))%max)).add(min);
    }

    function distributeRandomBonus(
        uint8 tier
    ) external onlyOwner {
        require(
            !hasSaleStarted,
            "Sale hasn't finised yet."
        );

        uint256 randomId;

        if (tier == 1) {
            randomId = getRandomNumber(0, 999);
        } else if (tier == 2) {
            randomId = getRandomNumber(1000, 2999);
        } else if (tier == 3) {
            randomId = getRandomNumber(3000, 4999);
        } else if (tier == 4) {
            randomId = getRandomNumber(5000, 5999);
        } else if (tier == 5) {
            randomId = getRandomNumber(6000, 6299);
        } else if (tier == 6) {
            randomId = getRandomNumber(6300, 6394);
        } else if (tier == 7) {
            randomId = getRandomNumber(6395, 6399);
        } else {
            return;
        }

        uint256 bonus = getRandomNumber(0, 1E18);
        
        if (bonus > 0) {
            _apymonpack.increaseInsideTokenBalance(
                randomId,
                1, // TOKEN_TYPE_ERC20
                address(_weth),
                bonus
            );

            _weth.deposit{ value: bonus }();
            _weth.transfer(address(_apymonpack), bonus);
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
       _apymonpack = IApymonPack(apymonpack);
    }

    function setProvenance(string memory _provenance) onlyOwner external {
        APYMON_PROVENANCE = _provenance;
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

        if (referee != address(0) && referee != to) {
            _addReferralAmount(referee, to, msg.value);
        }
    }

    /**
     * @dev Mints creature to apymonpacks.
     * Creatures must be distributed to owners of egg.
     */
    function mintCreature(
        uint256 eggId
    ) external {
        require(msg.sender == address(_apymonpack));
        require(eggId < MAX_EGG_SUPPLY);
        require(
            !hasSaleStarted,
            "Sale hasn't finised yet."
        );
        uint256 creatureId = eggId + MAX_EGG_SUPPLY;
        require(!_exists(creatureId));
        _safeMint(address(_apymonpack), creatureId);
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