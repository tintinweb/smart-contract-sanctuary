// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IUniswapV2.sol";
import "./IBasket.sol";
import "./IBasicIssuanceModule.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./BDIMarketMaker.sol";

// Mint tokens with a delay
contract DelayedMinter is MarketMakerMinter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Can only mint after 20 mins, and only has a 20 mins window to mint
    // 20 min window to mint
    uint256 public mintDelaySeconds = 1200;
    uint256 public maxMintDelaySeconds = 2400;

    address public governance;

    // User deposited
    mapping(address => uint256) public deposits;

    // When user deposited
    mapping(address => uint256) public timestampWhenDeposited;

    // Blacklist
    mapping(address => bool) public isBlacklisted;

    // **** Constructor and modifiers ****

    constructor(address _governance) {
        governance = _governance;

        // Enter compound markets
        address[] memory markets = new address[](2);
        markets[0] = CUNI;
        markets[0] = CCOMP;
        enterMarkets(markets);

        IERC20(WETH).safeApprove(SUSHISWAP_ROUTER, uint256(-1));
        IERC20(WETH).safeApprove(UNIV2_ROUTER, uint256(-1));
    }

    receive() external payable {}

    // **** Modifiers ****

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!eoa");
        _;
    }

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "blacklisted");
        _;
    }

    // **** Restricted functions ****

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    function recoverERC20(address _token) public onlyGov {
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }

    function recoverERC20s(address[] memory _tokens) public onlyGov {
        for (uint256 i = 0; i < _tokens.length; i++) {
            recoverERC20(_tokens[i]);
        }
    }

    function setMintDelaySeconds(uint256 _seconds) public onlyGov {
        mintDelaySeconds = _seconds;
    }

    function setMaxMintDelaySeconds(uint256 _seconds) public onlyGov {
        maxMintDelaySeconds = _seconds;
    }

    function setBlacklist(address _user, bool _b) public onlyGov {
        isBlacklisted[_user] = _b;
    }

    // **** Public Functions ****

    function deposit() public payable {
        require(msg.value > 0, "!value");

        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        timestampWhenDeposited[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 _amount) public {
        deposits[msg.sender] = deposits[msg.sender].sub(_amount);

        (bool success, ) = msg.sender.call{ value: _amount }("");
        require(success, "!eth-transfer");
    }

    /// @notice Converts ETH into a Basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasket  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasket  How much 1 basket token is worth in ETH
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function mintWithETH(
        address[] memory routers,
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasket,
        uint256 ethPerBasket,
        uint256 minMintAmount,
        uint256 deadline
    ) public onlyEOA notBlacklisted returns (uint256) {
        require(block.timestamp <= deadline, "expired");

        uint256 _amount = deposits[msg.sender];

        require(_amount > 0, "!amount");
        require(_canMint(timestampWhenDeposited[msg.sender]), "!timestamp");

        uint256 sum = 0;
        for (uint256 i = 0; i < underlyingsInEthPerBasket.length; i++) {
            sum = sum.add(underlyingsInEthPerBasket[i]);
        }
        require(ethPerBasket >= sum, "!valid-inputs");

        // Wrap user amount ETH to WETH
        IWETH(WETH).deposit{ value: deposits[msg.sender] }();

        // BDPI to mint
        uint256 bdpiToMint =
            _convertETHToDerivativeAndGetMintAmount(
                routers,
                derivatives,
                underlyings,
                underlyingsInEthPerBasket,
                ethPerBasket
            );

        // Reset deposit
        deposits[msg.sender] = 0;

        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Mint tokens and transfer to user
        BDPI.mint(bdpiToMint);
        IERC20(address(BDPI)).safeTransfer(msg.sender, bdpiToMint);

        return bdpiToMint;
    }

    // **** Internal functions ****

    function _canMint(uint256 _depositTime) public view returns (bool) {
        return
            block.timestamp >= _depositTime + mintDelaySeconds && block.timestamp <= _depositTime + maxMintDelaySeconds;
    }
}