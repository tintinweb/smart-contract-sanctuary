// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./DragonSlayerInterface.sol";
import "./SafeMath.sol";
import "./ManagerInterface.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract DragonSlayer is ERC20, ERC20Burnable, Ownable, DragonSlayerInterface {
    using SafeMath for uint256;

    uint256 MAX_TOTAL_SUPPLY         = 1000000000 * 10 ** 9;
    uint256 MAX_TOKENS_FOR_REWARDS   = 200000000  * 10 ** 9;
    uint256 MAX_TOKENS_FOR_MARKETING = 30000000   * 10 ** 9;
    uint256 MAX_TOKENS_FOR_AIRDROP   = 20000000   * 10 ** 9;

    mapping(address => bool)    botAddresses;
    mapping(address => uint256) private airdropWhitelist;

    ManagerInterface public manager;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public addressForMarketing;
    
    uint256 public tokensForMarketing = MAX_TOKENS_FOR_MARKETING;
    uint256 public tokensForRewards   = MAX_TOKENS_FOR_REWARDS;
    uint256 public tokensForAirdrop   = MAX_TOKENS_FOR_AIRDROP;

    // Anti bot-trade
    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;
    
    // Transfer fee
    uint256 public sellFeeRate = 6;
    uint256 public buyFeeRate = 5;
    
    address payable public marketingAddress = payable(0x7c5C50bBBa874B7E55DA5327C13E6613B47B2b8E); // Marketing Address
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    // mapping (address => uint256) private _rOwned;
    // mapping (address => uint256) private _tOwned;
    // mapping (address => mapping (address => uint256)) private _allowances;

    modifier onlySupporter () {
        require(manager.onlySupporter(_msgSender()), "Caller is not supporter");
        _;
    }
    
    constructor() ERC20("DragonSlayer", "DRS") {
        addressForMarketing = _msgSender();

        _mint(_msgSender(), MAX_TOTAL_SUPPLY.sub(tokensForAirdrop).sub(tokensForRewards));
        _mint(address(this), tokensForAirdrop.add(tokensForRewards));
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        IUniswapV2Factory  _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        uniswapV2Pair   = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    
    /**
     * Set an address of the gameplay management contract.
     */
    function setManager(address _manager) public onlyOwner {
        manager = ManagerInterface(_manager);
    }

    function setMinTokensBeforeSwap(uint256 _tokensForMarketing) public onlyOwner {
        require(_tokensForMarketing < MAX_TOKENS_FOR_MARKETING);
        tokensForMarketing = _tokensForMarketing;
    }

    function setTokensForRewards(uint256 _tokensForRewards) public onlyOwner {
        require(_tokensForRewards < MAX_TOKENS_FOR_REWARDS);
        tokensForRewards = _tokensForRewards;
    }

    function setTokensForAirdrop(uint256 _tokensForAirdrop) public onlyOwner {
        require(_tokensForAirdrop < MAX_TOKENS_FOR_REWARDS);
        tokensForAirdrop = _tokensForAirdrop;
    }

    function addAirdropWhitelist(address[] memory to, uint256[] memory amount)
        public
        onlyOwner
    {
        require(to.length == amount.length, "Invalid arguments");

        for (uint256 index = 0; index < to.length; index++) {
            airdropWhitelist[address(to[index])] = amount[index];
        }
    }

    /**
     * Allows users to claim tokens from an airdrop.
     */
    function claimAirdrop () public {
        require(airdropWhitelist[_msgSender()] > 0, "It's not possible to claim an airdrop at this address.");
        require(tokensForAirdrop > 0, "The amount of tokens available for the airdrop has been exhausted.");
        
        _transfer(address(this), _msgSender(), airdropWhitelist[_msgSender()]);
        tokensForAirdrop = tokensForAirdrop.sub(airdropWhitelist[_msgSender()]);
        airdropWhitelist[_msgSender()] = 0;
    }

    function setBotAddresses (address[] memory _addresses) external onlyOwner {
        require(_addresses.length > 0);

        for (uint256 index = 0; index < _addresses.length; index++) {
            botAddresses[address(_addresses[index])] = true;
        }
    }

    function addBotAddress (address _address) external onlyOwner {
        require(!botAddresses[_address]);

        botAddresses[_address] = true;
    }

    /**
     * To prevent bot trading, limit the number of tokens that can be transferred.
     */
    function antiBot(uint256 amount) external onlyOwner {
        require(amount > 0, "not accept 0 value");
        require(!antiBotEnabled);

        antiBotAmount = amount;
        antiBotTime = block.timestamp + antiBotDuration;
        antiBotEnabled = true;
    }
    
    function sweepTokenForMarketing(uint256 amount) public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (tokensForMarketing >= amount && contractTokenBalance > amount) {
            swapTokensForEth(amount);
        }
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        require(addressForMarketing != address(0), "Invalid marketing address");

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            addressForMarketing, // The contract
            block.timestamp
        );

        tokensForMarketing = tokensForMarketing.sub(tokenAmount);
    }
    
    /**
     * After the user has won the game, send them a reward.
     */
    function rewards(address recipient, uint256 amount) override external onlySupporter {
        require(recipient != address(0), "0x is not accepted here");
        require(tokensForRewards > 0, "Rewards not available");
        require(amount > 0, "not accept 0 value");

        if (tokensForRewards >= amount) {
            _mint(recipient, amount);
            tokensForRewards = tokensForRewards.sub(amount);
        } else {
            _mint(recipient, tokensForRewards);
            tokensForRewards = 0;
        }
    }

    function setAddressForMarketing(address _address) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");

        addressForMarketing = _address;
    }

    /**
     * Add a bot prevention feature by overriding the _transfer function.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            antiBotTime > block.timestamp &&
            amount > antiBotAmount &&
            botAddresses[sender]
        ) {
            revert("Anti Bot");
        }

        uint256 transferFeeRate = recipient == uniswapV2Pair
            ? sellFeeRate
            : (sender == uniswapV2Pair ? buyFeeRate : 0);

        if (
            transferFeeRate > 0 &&
            sender != address(this) &&
            recipient != address(this)
        ) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            super._transfer(sender, address(this), _fee);
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }
    
    // receive eth from uniswap swap
    receive() external payable {}
}