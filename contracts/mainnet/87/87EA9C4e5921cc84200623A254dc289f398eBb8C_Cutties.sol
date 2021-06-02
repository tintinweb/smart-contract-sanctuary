// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./INonfungiblePositionManager.sol";
import "./IWETH9.sol";
import "./ICUTTToken.sol";

contract Cutties is ERC721, Ownable {
    using SafeMath for uint256;

    string public CUTTIES_PROVENANCE = "";

    uint256 public constant MAX_CUTTIES_SUPPLY = 10000;

    uint256 private _liquidityTokenAmount = 200000000 * 10**6 * 10**9;

    bool public hasSaleStarted = false;

    address payable private constant _team =
        payable(0x375063822A5987d83bfc13398C095de89a4730a0);
    address public _treasuryAddress;
    address public _cuttToken;
    address private _weth9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private _nonfungiblePositionManager =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    constructor(string memory baseURI) ERC721("Cutties", "CUTTIES") {
        _setBaseURI(baseURI);
        _treasuryAddress = msg.sender;
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
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function getMintableCount() public view returns (uint256) {
        uint256 cuttiesupply = totalSupply();

        if (cuttiesupply >= MAX_CUTTIES_SUPPLY) {
            return 0;
        } else if (cuttiesupply >= 9990) {
            // 9991 ~ 10000
            return 1;
        } else if (cuttiesupply >= 9900) {
            // 9901 ~ 9990
            return 5;
        } else {
            // 1 ~ 9900
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

    function getCuttTokenAmount() public view returns (uint256) {
        uint256 cuttiesupply = totalSupply();

        if (cuttiesupply >= MAX_CUTTIES_SUPPLY) {
            return 0;
        } else if (cuttiesupply >= 9990) {
            // 9990 ~ 9999
            return uint256(496130184560).mul(10**9).div(10);
        } else if (cuttiesupply >= 9900) {
            // 9900 ~ 9989
            return uint256(2857709863068).mul(10**9).div(90);
        } else if (cuttiesupply >= 8900) {
            // 8900 ~ 9899
            return uint256(23814248858901).mul(10**9).div(1000);
        } else if (cuttiesupply >= 6700) {
            // 6700 ~ 8899
            return uint256(34927564993054).mul(10**9).div(2200);
        } else if (cuttiesupply >= 3200) {
            // 3200 ~ 6699
            return uint256(27783290335384).mul(10**9).div(3500);
        } else if (cuttiesupply >= 1200) {
            // 1200 ~ 3199
            return uint256(7938082952967).mul(10**9).div(2000);
        } else if (cuttiesupply >= 200) {
            // 200 ~ 1199
            return uint256(1984520738242).mul(10**9).div(1000);
        } else {
            // 0 ~ 199
            return uint256(198452073824).mul(10**9).div(200);
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        CUTTIES_PROVENANCE = _provenance;
    }

    function mintCutties(address to, uint256 count) external payable {
        require(_cuttToken != address(0));
        uint256 cuttiesupply = totalSupply();
        require(hasSaleStarted);
        require(count > 0 && count <= getMintableCount());
        require(SafeMath.add(cuttiesupply, count) <= MAX_CUTTIES_SUPPLY);
        require(SafeMath.mul(getCuttiesPrice(), count) == msg.value);

        uint256 tokenAmount = getCuttTokenAmount();
        ICUTTToken(_cuttToken).transfer(to, tokenAmount.mul(count));

        for (uint8 i; i < count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
        }
    }

    function reserveCutties() external onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

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

    function setLiquidityTokenAmount(uint256 liquidityTokenAmount)
        public
        onlyOwner
    {
        _liquidityTokenAmount = liquidityTokenAmount;
    }

    function mintLiquidityAndCuttiesToken() public onlyOwner {
        require(_cuttToken != address(0));
        ICUTTToken(_cuttToken).mintLiquidityToken();
        ICUTTToken(_cuttToken).mintCuttiesToken();
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
        uint256 cuttBalance =
            ICUTTToken(_cuttToken).balanceOf(address(this)) >=
                _liquidityTokenAmount
                ? _liquidityTokenAmount
                : ICUTTToken(_cuttToken).balanceOf(address(this));
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

    function createPoolAndLiquidity(
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) public onlyOwner {
        require(_cuttToken != address(0));
        require(!hasSaleStarted);
        (address token0, address token1) = getTokens();
        (uint256 balance0, uint256 balance1) = getTokenBalances();
        require(balance0 > 0);
        require(balance1 > 0);

        uint160 sqrtPriceX96 =
            (sqrt(uint160(balance1)) << 96) / sqrt(uint160(balance0));

        address poolAddress =
            INonfungiblePositionManager(_nonfungiblePositionManager)
                .createAndInitializePoolIfNecessary{
                value: address(this).balance
            }(token0, token1, fee, sqrtPriceX96);

        ICUTTToken(_cuttToken).setPoolAddress(poolAddress);

        ICUTTToken(_cuttToken).approve(
            _nonfungiblePositionManager,
            _liquidityTokenAmount
        );

        INonfungiblePositionManager.MintParams memory data =
            INonfungiblePositionManager.MintParams(
                token0,
                token1,
                fee,
                tickLower,
                tickUpper,
                balance0,
                balance1,
                0,
                0,
                address(this),
                (uint256)(block.timestamp).add(1000)
            );

        INonfungiblePositionManager(_nonfungiblePositionManager).mint(data);
    }

    function setTreasuryAddress(address treasuryAddress) public {
        require(msg.sender == _treasuryAddress);
        _treasuryAddress = treasuryAddress;
    }

    function withdrawNFT(uint256 tokenId) external {
        require(msg.sender == _treasuryAddress);
        INonfungiblePositionManager(_nonfungiblePositionManager).approve(
            _treasuryAddress,
            tokenId
        );
        INonfungiblePositionManager(_nonfungiblePositionManager).transferFrom(
            address(this),
            _treasuryAddress,
            tokenId
        );
    }

    function burnExtraToken() public onlyOwner {
        require(_cuttToken != address(0));
        require(!hasSaleStarted);
        uint256 amount = ICUTTToken(_cuttToken).balanceOf(address(this));
        ICUTTToken(_cuttToken).burn(amount);
    }
}