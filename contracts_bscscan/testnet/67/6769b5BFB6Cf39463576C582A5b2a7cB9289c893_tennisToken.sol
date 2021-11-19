/**

MINITENNIS TOKEN 

REWARDS IN ADA

Contact us: 
🟣 Telegram: https://
🟣 Website: https://
🟣 Facebook: https://
🟣 Twitter: https://
🟣 Discord: https://

----TOKENOMICS-----

🟣Total circulating supply: 1.000.000.000.000.

🟢 Buy fee 10%:
    🔹 3% reward
    🔹 3% marketing
    🔹 3% buyback
    🔹 1% development
    

🔴 Sell fee 20%:
    🔹  3% reward
    🔹  4% marketing
    🔹  7% development
    🔹  6% buyback&liquidity (4% buyback ,2% liquidez)

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Address.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract tennisToken is ERC20, AccessControl, Pausable {
    // CONFIG START

    uint256 denominator = 100;
    
    // TOKEN
    string tokenName = "tennis";
    string tokenSymbol = "tennis";
    uint256 tokenTotalSupply = 1_000_000_000_000 * (10**18);
    
    // ADRESSES
    address devWallet = 0x8415A2e42FC3586b2FDEE68AAE40D62f094F3770;
    address marketingWallet = 0x0798585058619B19Ce9b7B07A62Cd6EBe8e79826;
    address buybackWallet = 0xfBbe78BA89BE65a31Ac18cA712E1ec710e48d73F;
    address router02 = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    // BUY TAX
    uint256 public devTaxBuy = 1;
    uint256 public marketingTaxBuy = 3;
    uint256 public buybackTaxBuy = 3;
    uint256 public redistributeTaxBuy = 3;

    // SELL TAX
    uint256 public devTaxSell = 7;
    uint256 public marketingTaxSell = 4;
    uint256 public buybackTaxSell = 6;
    uint256 public redistributeTaxSell = 3;

    uint256 public maxTxAmount = 100_000_000 * 10**18 + 1;
    uint256 public maxWalletAmount = 100_000_000 * 10**18 + 1;

    // REDISTRIBUTION
    address public token = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47; //ADA
    
    // CONFIG END

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    
    IUniswapV2Router02 private _UniswapV2Router02;
    IUniswapV2Factory private _UniswapV2Factory;
    IUniswapV2Pair private _UniswapV2Pair;
    
    mapping (address => uint256) private nextBuyBlock;
    
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExcludedFromBotProtection;

    // Whitelist
    bool public whitelistStatus;
    mapping (address => bool) public isWhitelisted;

    // Blacklist
    bool public blacklistStatus;
    mapping (address => bool) public isBlacklisted;
    
    uint256 private feeTokens;

    uint256 private devTokens;
    uint256 private marketingTokens;
    uint256 private buybackTokens;
    uint256 private redistributionTokens;

    bool public taxStatus;
    bool public BPStatus;
    
    using Address for address;

    uint256 totalHolded;

    event LogNum(string, uint256);
    event LogBool(string, bool);
    event LogAddress(string, address);
    event LogString(string, string);
    event LogBytes(string, bytes);
    
    constructor(address owner) ERC20(tokenName, tokenSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, owner);

        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _UniswapV2Factory = IUniswapV2Factory(_UniswapV2Router02.factory());
        _UniswapV2Pair = IUniswapV2Pair(_UniswapV2Factory.createPair(address(this), _UniswapV2Router02.WETH()));
        
        isExcluded[msg.sender] = true;
        isExcluded[marketingWallet] = true;
        isExcluded[address(this)] = true;

        isExcludedFromBotProtection[address(_UniswapV2Pair)] = true;

        taxStatus = true;
        BPStatus = true;
        
        _mint(owner, tokenTotalSupply);
    }

    bool inTax;
    
    function handleFees(address sender, address recipient, uint256 amount) internal returns (uint256 fee) {
        bool isBuy = sender == address(_UniswapV2Pair);
        bool isSell = recipient == address(_UniswapV2Pair);

        uint256 fees;
        uint256 taxSum;

        uint256 devAmount;
        uint256 marketingAmount;
        uint256 buybackAmount;
        uint256 redistributionAmount;

        if(isBuy) {
            fees = amount * 10**18 / denominator * (devTaxBuy + marketingTaxBuy + buybackTaxBuy + redistributeTaxBuy) / 10**18;

            taxSum = devTaxBuy + marketingTaxBuy + buybackTaxBuy + redistributeTaxBuy;

            devAmount = fees * 10**18 / taxSum * devTaxBuy / 10**18;
            marketingAmount = fees * 10**18 / taxSum * marketingTaxBuy / 10**18;
            buybackAmount = fees * 10**18 / taxSum * buybackTaxBuy / 10**18;
            redistributionAmount = fees * 10**18 / taxSum * redistributeTaxBuy / 10**18;

            feeTokens += fees;

            devTokens += devAmount;
            marketingTokens += marketingAmount;
            buybackTokens += buybackAmount;
            redistributionTokens += redistributionAmount;

            super._transfer(sender, address(this), fees);
        } else if(isSell) {
            fees = amount * 10**18 / denominator * (devTaxSell + marketingTaxSell + buybackTaxSell + redistributeTaxSell) / 10**18;

            taxSum = devTaxSell + marketingTaxSell + buybackTaxSell + redistributeTaxSell;
            
            devAmount = fees * 10**18 / taxSum * devTaxSell / 10**18;
            marketingAmount = fees * 10**18 / taxSum * marketingTaxSell / 10**18;
            buybackAmount = fees * 10**18 / taxSum * buybackTaxSell / 10**18;
            redistributionAmount = fees * 10**18 / taxSum * redistributeTaxSell / 10**18;

            feeTokens += fees;

            devTokens += devAmount;
            marketingTokens += marketingAmount;
            buybackTokens += buybackAmount;
            redistributionTokens += redistributionAmount;

            super._transfer(sender, address(this), fees);

            if(feeTokens > 0) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _UniswapV2Router02.WETH();
                
                uint256 startBalance = address(this).balance;
                
                _approve(address(this), address(_UniswapV2Router02), feeTokens);

                inTax = true;
                
                _UniswapV2Router02.swapExactTokensForETH(
                    feeTokens,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                
                uint256 ethGained = address(this).balance - startBalance;
                
                Address.sendValue(payable(marketingWallet), marketingTokens * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(buybackWallet), buybackTokens * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devWallet), devTokens * 10**18 / feeTokens * ethGained / 10**18);

                address[] memory currentPath = new address[](2);
                currentPath[0] = _UniswapV2Router02.WETH();
                currentPath[1] = token;

                if(redistributionTokens > 0) {
                    _UniswapV2Router02.swapExactETHForTokens{value: redistributionTokens * 10**18 / feeTokens * ethGained / 10**18}(
                        0,
                        currentPath,
                        address(this),
                        block.timestamp
                    );
                }

                inTax = false;

                devTokens = 0;
                feeTokens = 0;
                marketingTokens = 0;
                buybackTokens = 0;
                redistributionTokens = 0;
            }
        }

        return fees;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        if(isExcluded[msg.sender] || isExcluded[tx.origin] || inTax) {
            super._transfer(sender, recipient, amount);
        } else {
            if(!isExcluded[sender] && !isExcluded[recipient]) {
                require(!paused(), "HFT: Transfers paused");
                require(isExcluded[recipient] || recipient == address(_UniswapV2Pair)|| balanceOf(recipient) + amount <= maxWalletAmount, "HFT: Max wallet amount");
                require(!blacklistStatus || (!isBlacklisted[sender] && !isBlacklisted[recipient]), "HFT: Blacklisted");
                require(!whitelistStatus || (isWhitelisted[sender] && isWhitelisted[recipient]), "HFT: Not Whitelisted");

                if(sender == address(_UniswapV2Pair) || recipient == address(_UniswapV2Pair)) {
                    if(sender == address(_UniswapV2Pair)) {
                        require(block.number >= nextBuyBlock[recipient], "HFT: Cooldown");
                        require(amount <= maxTxAmount, "HFT: Max tx amount");

                        nextBuyBlock[recipient] = block.number + 1;
                    }

                    if(taxStatus) {
                        uint256 fees = handleFees(sender, recipient, amount);
                        amount -= fees; 
                    }            
                }
            }

            if(BPStatus) {
                if(sender == address(_UniswapV2Pair) && !isExcludedFromBotProtection[recipient]) {
                    require(!recipient.isContract(), "HFT: Bot Protection");
                } else if(recipient == address(_UniswapV2Pair) && !isExcludedFromBotProtection[sender]) {
                    require(!sender.isContract(), "HFT: Bot Protection");
                }
            }

            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * Pause & Unpause
     */
    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }



    /**
     * General settings
     */

    function setToken(address newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != token, "HFT: Value already set to that option");

        token = newValue;
    }

    function setDenominator(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != denominator, "HFT: Value already set to that option");

        denominator = newValue;
    }

    function setMaxTxAmount(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != maxTxAmount, "HFT: Value already set to that option");

        maxTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != maxWalletAmount, "HFT: Value already set to that option");

        maxWalletAmount = newValue;
    }



    /**
     * Exclude
     */

    function setExcluded(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isExcluded[account], "HFT: Value already set to that option");

        isExcluded[account] = newValue;
    }

    function setExcludedFromBotProtection(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isExcludedFromBotProtection[account], "HFT: Value already set to that option");

        isExcludedFromBotProtection[account] = newValue;
    }

    function massSetExcluded(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcluded[accounts[i]], "HFT: Value already set to that option");

            isExcluded[accounts[i]] = newValue;
        }
    }

    function massSetExcludedFromBotProtection(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcludedFromBotProtection[accounts[i]], "HFT: Value already set to that option");

            isExcludedFromBotProtection[accounts[i]] = newValue;
        }
    }



    /**
     * Blacklist & whitelist
     */

    function setBlacklistStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(blacklistStatus != newValue, "HFT: Value already set to that option");

        blacklistStatus = newValue;
    }

    function setWhitelistStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(whitelistStatus != newValue, "HFT: Value already set to that option");

        whitelistStatus = newValue;
    }

    function setBlacklisted(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isBlacklisted[account], "HFT: Value already set to that option");

        isBlacklisted[account] = newValue;
    }

    function setWhitelisted(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isWhitelisted[account], "HFT: Value already set to that option");

        isWhitelisted[account] = newValue;
    }

    function massSetBlacklisted(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isBlacklisted[accounts[i]], "HFT: Value already set to that option");

            isBlacklisted[accounts[i]] = newValue;
        }
    }

    function massSetWhitelisted(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isWhitelisted[accounts[i]], "HFT: Value already set to that option");

            isWhitelisted[accounts[i]] = newValue;
        }
    }



    /**
     * Taxes
     */

    function setTaxesBuy(uint256 dev, uint256 marketing, uint256 buyback, uint256 redistribution) external onlyRole(OWNER_ROLE) {
        devTaxBuy = dev;
        marketingTaxBuy = marketing;
        buybackTaxBuy = buyback;
        redistributeTaxBuy = redistribution;
    }

    function setTaxesSell(uint256 dev, uint256 marketing, uint256 buyback, uint256 redistribution) external onlyRole(OWNER_ROLE) {
        devTaxSell = dev;
        marketingTaxSell = marketing;
        buybackTaxSell = buyback;
        redistributeTaxSell = redistribution;
    }

    function setTaxStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(taxStatus != newValue, "HFT: Value already set to that option");

        taxStatus = newValue;
    }

    function setBotProtectionStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(BPStatus != newValue, "HFT: Value already set to that option");

        BPStatus = newValue;
    }

    function withdrawETH(address to, uint256 value) external onlyRole(OWNER_ROLE) {
        require(address(this).balance >= value, "HFT: Insufficient ETH balance");

        (bool success,) = to.call{value: value}("");
        require(success, "HFT: Transfer failed");
    }

    function withdrawTokens(address tokenAddress, address to, uint256 value) external onlyRole(OWNER_ROLE) {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= value, "HFT: Insufficient token balance");

        try IERC20(tokenAddress).transfer(to, value) {} catch {
            revert("HFT: Transfer failed");
        }
    }
    
    receive() external payable {}
}