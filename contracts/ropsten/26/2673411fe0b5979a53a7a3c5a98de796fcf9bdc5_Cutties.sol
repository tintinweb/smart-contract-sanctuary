// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./INonfungiblePositionManager.sol";
import "./IWETH9.sol";

interface ICUTTToken {
    function mintLiqudityToken() external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Cutties is ERC721, Ownable {
    using SafeMath for uint256;

    string public CUTTIES_PROVENANCE = "";

    // Maximum amount of Cutties in existance. Ever.
    uint256 public constant MAX_CUTTIES_SUPPLY = 10000;

    bool public hasSaleStarted = false;

    address payable private constant _team =
        payable(0x9c2ad34b45CaC92d3E7f53ec6AF247c2F51c2758);
    address public _cuttToken;
    address public _weth9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _nonfungiblePositionManager =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

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
        uint256 count
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

    function setTokenAddress(address tokenAddress) public onlyOwner {
        _cuttToken = tokenAddress;
    }

    function mintLiqudityToken() public onlyOwner {
        require(_cuttToken != address(0));
        ICUTTToken(_cuttToken).mintLiqudityToken();
    }

    function getTokens() public view returns (address token0, address token1) {
        token0 = (_weth9 < _cuttToken) ? _weth9 : _cuttToken;
        token1 = (_weth9 > _cuttToken) ? _weth9 : _cuttToken;
    }

    function getTokenBalances()
        public
        view
        returns (uint256 balance0, uint256 balance1)
    {
        uint256 cuttBalance = ICUTTToken(_cuttToken).balanceOf(address(this));
        uint256 ethBalance = address(this).balance;

        balance0 = (_weth9 < _cuttToken) ? ethBalance : cuttBalance;
        balance1 = (_weth9 > _cuttToken) ? ethBalance : cuttBalance;
    }

    function sqrt(uint160 x) internal pure returns (uint160 y) {
        uint160 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function test() public view onlyOwner returns (uint160) {
        require(_cuttToken != address(0));
        (uint256 balance0, uint256 balance1) = getTokenBalances();
        require(balance0 > 0);
        require(balance1 > 0);

        uint160 sqrtPriceX96 =
            ((sqrt(uint160(address(this).balance)) << 96) /
                sqrt(uint160(ICUTTToken(_cuttToken).balanceOf(address(this)))));
        return sqrtPriceX96;
    }

    function createPoolAndLiquidity() public onlyOwner {
        require(_cuttToken != address(0));
        (address token0, address token1) = getTokens();
        (uint256 balance0, uint256 balance1) = getTokenBalances();
        uint24 fee = 500; // 500, 3000, 10000
        require(balance0 > 0);
        require(balance1 > 0);

        uint160 sqrtPriceX96 =
            (sqrt(uint160(balance1)) << 96) / sqrt(uint160(balance0));

        INonfungiblePositionManager(_nonfungiblePositionManager)
            .createAndInitializePoolIfNecessary{value: address(this).balance}(
            token0,
            token1,
            fee,
            sqrtPriceX96
        );

        ICUTTToken(_cuttToken).approve(
            _nonfungiblePositionManager,
            ICUTTToken(_cuttToken).balanceOf(address(this))
        );

        INonfungiblePositionManager.MintParams memory data =
            INonfungiblePositionManager.MintParams(
                token0,
                token1,
                fee,
                -887270, // -887270, -887220, -887200
                887270, //   887270,  887220,  887200
                balance0,
                balance1,
                0,
                0,
                address(this),
                (uint256)(block.timestamp).add(1000)
            );

        // (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) =
        //     INonfungiblePositionManager(_nonfungiblePositionManager).mint(data);
    }
}