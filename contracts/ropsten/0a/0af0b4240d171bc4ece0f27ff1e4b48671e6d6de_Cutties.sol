// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";

interface ERC20Interface is IERC20 {
    function deposit() external payable;
}

interface ICUTTToken {
    function mintLiqudityToken() external;

    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address addres) external view returns (uint256);
}

contract Cutties is ERC721, Ownable {
    using SafeMath for uint256;

    string public CUTTIES_PROVENANCE = "";

    // Maximum amount of Cutties in existance. Ever.
    uint256 public constant MAX_CUTTIES_SUPPLY = 10000;

    // Referral management
    mapping(address => uint256) public _referralAmounts;
    mapping(address => mapping(address => bool)) public _referralStatus;

    ERC20Interface private constant _weth =
        ERC20Interface(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 // mainnet
        );

    address payable private constant _team =
        payable(0x9c2ad34b45CaC92d3E7f53ec6AF247c2F51c2758);

    bool public hasSaleStarted = false;

    address public CUTTToken;

    constructor(string memory baseURI) ERC721("Cutties", "CUTTIES") {
        _setBaseURI(baseURI);
    }

    function deposit() external payable {}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
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
     * @dev Gets cutties count to mint per once.
     */
    function getMintableCount() public view returns (uint256) {
        uint256 cuttiesupply = totalSupply();

        if (cuttiesupply >= MAX_CUTTIES_SUPPLY) {
            return 0;
        } else if (cuttiesupply >= 9970) {
            // 9971 ~ 10000
            return 1;
        } else if (cuttiesupply >= 9200) {
            // 9201 ~ 9970
            return 5;
        } else {
            // 1 ~ 9200
            return 20;
        }
    }

    function getCuttiesPrice() public view returns (uint256) {
        uint256 cuttiesupply = totalSupply();

        if (cuttiesupply >= MAX_CUTTIES_SUPPLY) {
            return 0;
        } else if (cuttiesupply >= 9990) {
            // 9990 ~ 9999
            return 1 ether;
        } else if (cuttiesupply >= 9900) {
            // 9900 ~ 9989
            return 0.64 ether;
        } else if (cuttiesupply >= 8900) {
            // 8900 ~ 9899
            return 0.48 ether;
        } else if (cuttiesupply >= 6700) {
            // 6700 ~ 8899
            return 0.32 ether;
        } else if (cuttiesupply >= 3200) {
            // 3200 ~ 6699
            return 0.16 ether;
        } else if (cuttiesupply >= 1200) {
            // 1200 ~ 3199
            return 0.08 ether;
        } else if (cuttiesupply >= 200) {
            // 200 ~ 1199
            return 0.04 ether;
        } else {
            return 0.02 ether; // 0 ~ 199
        }
    }

    function distributeReferral() external onlyOwner {
        require(!hasSaleStarted, "Sale hasn't finised yet.");

        for (uint256 i = 0; i < totalSupply(); i++) {
            address owner = ownerOf(i);
            uint256 referralAmount = _referralAmounts[owner];
            if (referralAmount > 0) {
                _weth.transfer(owner, referralAmount);
                delete _referralAmounts[owner];
            }
        }
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        CUTTIES_PROVENANCE = _provenance;
    }

    /**
     * @dev Mints yourself Cutties.
     */
    function mintCutties(
        address to,
        uint256 count,
        address referee
    ) public payable {
        uint256 cuttiesupply = totalSupply();
        require(hasSaleStarted, "Sale hasn't started.");
        require(count > 0 && count <= getMintableCount());
        require(SafeMath.add(cuttiesupply, count) <= MAX_CUTTIES_SUPPLY);
        require(SafeMath.mul(getCuttiesPrice(), count) == msg.value);

        for (uint256 i; i < count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
        }

        if (referee != address(0) && referee != to) {
            _addReferralAmount(referee, to, msg.value);
        }
    }

    /**
     * @dev send eth to team and treasury.
     */
    function withdraw(uint256 amount) external onlyOwner {
        _team.transfer(amount);
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
            _referralAmounts[referee] = _referralAmounts[referee].add(
                referralAmount
            );
            _referralAmounts[referrer] = _referralAmounts[referrer].add(
                referralAmount
            );
            _referralStatus[referrer][referee] = true;
        }
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        CUTTToken = tokenAddress;
    }

    function mintLiqudityToken() public onlyOwner {
        require(CUTTToken != address(0));
        ICUTTToken(CUTTToken).mintLiqudityToken();
    }
}