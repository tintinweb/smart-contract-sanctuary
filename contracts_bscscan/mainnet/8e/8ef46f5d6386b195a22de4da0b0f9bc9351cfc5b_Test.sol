// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ManagerInterface.sol";

contract Test is ERC20, ERC20Burnable, Pausable, Ownable {
    using SafeMath for uint256;

    mapping(address => bool)    botAddresses;
    mapping(address => uint256) private airdropWhitelist;
    mapping(address => uint)    private lotterySpin;
    mapping(address => uint256) private lotteryRewards;

    ManagerInterface public manager;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public addressForMarketing;
    
    uint256 public maxSupply    = 1000000 * 10 ** 9; // Total supply: 1000000000
    uint256 public availableMarketing = 30000   * 10 ** 9; // 3% for marketing
    
    // Tokens for rewards
    uint256 public availableRewards = 200000  * 10 ** 9; // 20% for rewards
    
    // Tokens for airdrop
    uint256 public availableAirdrop = 20000   * 10 ** 9; // 2% for airdrop

    // Anti bot-trade
    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;
    
    // Transfer fee
    uint256 public sellFeeRate = 6;
    uint256 public buyFeeRate = 5;

    modifier onlyEvolver () {
        require(manager.onlyEvolver(_msgSender()), "Caller is not evolver");
        _;
    }
    
    constructor() ERC20("Test", "TEST") {
        _mint(_msgSender(), maxSupply.sub(availableAirdrop).sub(availableRewards).sub(availableMarketing));
        _mint(address(this), availableAirdrop.add(availableMarketing).add(availableRewards));
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * Set address of management contract
     */
    function setManager(address _manager) public onlyOwner {
        manager = ManagerInterface(_manager);
    }

    function setMinTokensBeforeSwap(uint256 _tokenForMarketing)
        public
        onlyOwner
    {
        require(_tokenForMarketing < 30000000   * 10 ** 18);
        availableMarketing = _tokenForMarketing;
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
     * Claim airdrop tokens
     */
    function claimAirdrop () public {
        require(airdropWhitelist[_msgSender()] > 0, "You cannot claim token anymore.");
        require(availableAirdrop > 0, "The amount of tokens for the airdrop has run out.");
        
        _transfer(address(this), _msgSender(), airdropWhitelist[_msgSender()]);
        availableAirdrop = availableAirdrop.sub(airdropWhitelist[_msgSender()]);
        airdropWhitelist[_msgSender()] = 0;
    }

    /**
     * Set maximium tokens can be transfer to prevent bot trading
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
        if (availableMarketing >= amount && contractTokenBalance > amount) {
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

        availableMarketing = availableMarketing.sub(tokenAmount);
    }
    
    /**
     * Send rewards to user after win the game
     */
    function rewards(address recipient, uint256 amount) external onlyEvolver {
        require(recipient != address(0), "0x is not accepted here");
        require(availableRewards > 0, "Rewards not available");
        require(amount > 0, "not accept 0 value");

        if (availableRewards >= amount) {
            _mint(recipient, amount);
            availableRewards = availableRewards.sub(amount);
        } else {
            _mint(recipient, availableRewards);
            availableRewards = 0;
        }
    }

    function setAddressForMarketing(address _address) external onlyOwner {
        require(_address != address(0), "0x is not accepted here");

        addressForMarketing = _address;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * Override _transfer function to adding bot prevention feature
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