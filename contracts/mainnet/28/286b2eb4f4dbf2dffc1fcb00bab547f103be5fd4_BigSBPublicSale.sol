// SPDX-License-Identifier: UNLICENSE

/**
Apes Together Strong!

About BigShortBets DeFi project:

We are creating a social&trading p2p platform that guarantees encrypted interaction between investors.
Logging in is possible via a cryptocurrency wallet (e.g. Metamask).
The security level is one comparable to the Tor network.

https://bigsb.io/ - Our Tool
https://bigshortbets.com - Project&Team info

Video explainer:
https://youtu.be/wbhUo5IvKdk

Zaorski, You Son of a bitch I’m in …
*/

pragma solidity 0.8.7;
import "./owned.sol";
import "./reentryGuard.sol";
import "./interfaces.sol";

contract BigSBPublicSale is Owned, Guarded {
    constructor(
        address usdc,
        address usdt,
        address dai,
        address token,
        address oracle,
        uint256 amlLimit,
        Step[] memory steps
    ) {
        DAI = dai;
        USDT = usdt;
        USDC = usdc;
        BigSBaddress = token;
        ChainLinkOracle = oracle;
        uint256 i;
        for (i; i < steps.length; i++) {
            saleSteps.push(steps[i]);
        }
        // sale ends in 2 years
        saleEnd = block.timestamp + 730 days;
        maxDollarsPerUser = amlLimit;
    }

    // Claim contract that earn from fees
    address public claimContract;

    /// Struct decribing sale steps
    struct Step {
        uint256 lockLength; // how long tokens will be locked in contract (time in seconds)
        uint256 maxTokensPerUSD; // initial, maximum tokens per USD (min price)
        uint256 tokensPerUSD; // price in for given step
        uint256 tokenAmount; // how much tokens left on sale in this step (18 decimals)
    }

    /// Array of sale steps
    Step[] public saleSteps;

    /// last used step to not iterate full array every time
    uint256 public currentSaleStep;

    /// token address
    address public immutable BigSBaddress;

    /// Contract to get current ETH price
    address public immutable ChainLinkOracle;

    // stablecoins addresses
    address public immutable DAI;
    address public immutable USDT;
    address public immutable USDC;

    /// dollars per user
    mapping(address => uint256) public dollarsIn;

    /// aml limit (6 decimals)
    uint256 public maxDollarsPerUser;

    /// timestamp when owner can take all not sold tokens
    uint256 public immutable saleEnd;

    // ETH buy functions need 200k gas limit
    receive() external payable {
        _buyEth();
    }

    /// buy for ETH using DApp
    function buyEth() external payable {
        _buyEth();
    }

    // Calculate USD value and make transaction if possible
    function _buyEth() internal guarded {
        uint256 price = EthPrice();
        uint256 dollars = (msg.value * price) / 1 ether;
        uint256 refund = _buy(dollars);
        if (refund > 0) {
            require(
                payable(msg.sender).send((refund * 1 ether) / price),
                "Refund failed"
            );
        }
    }

    // Stablecoins buy need 300k gas limit

    /// buy for USDT using DApp, need approve first!
    function buyUsdt(uint256 amt) external guarded {
        // accept USDT token, it is not proper ERC20
        IUsdt(USDT).transferFrom(msg.sender, address(this), amt);
        uint256 refund = _buy(amt);
        if (refund > 0) {
            IUsdt(USDT).transfer(msg.sender, refund);
        }
    }

    /// buy for DAI using DApp, need approve first!
    function buyDai(uint256 amt) external guarded {
        // accept DAI token
        require(
            IERC20(DAI).transferFrom(msg.sender, address(this), amt),
            "DAI transfer failed"
        );
        // dai uses 18 decimals, we need only 6
        uint256 refund = _buy(amt / (10**12));
        if (refund > 0) {
            require(
                IERC20(DAI).transfer(msg.sender, refund * 10**12),
                "Refund failed"
            );
        }
    }

    /// buy for USDC using DApp, need approve first!
    function buyUsdc(uint256 amt) external guarded {
        // accept USDC token
        require(
            IERC20(USDC).transferFrom(msg.sender, address(this), amt),
            "USDC transfer failed"
        );
        uint256 refund = _buy(amt);
        if (refund > 0) {
            require(IERC20(USDC).transfer(msg.sender, refund), "Refund failed");
        }
    }

    // buy tokens for current step price
    // dollars with 6 decimals
    // move to next step if needed
    // make separate locks if passing threshold
    function _buy(uint256 dollars) internal returns (uint256 refund) {
        require(currentSaleStep < saleSteps.length, "Sale is over");
        require(claimContract != address(0), "Claim not configured");
        uint256 sum = dollarsIn[msg.sender] + dollars;
        require(sum < maxDollarsPerUser, "Over AML limit");
        dollarsIn[msg.sender] = sum;

        uint256 numLocks;

        Step memory s = saleSteps[currentSaleStep];
        uint256 tokens = (dollars * s.tokensPerUSD) / 1000000;
        uint256 timeNow = block.timestamp;
        uint256 toSale = s.tokenAmount;

        uint256 toSend;

        // check for step change
        if (tokens > toSale) {
            // set user lock at this step
            uint256 reflection = IReflect(BigSBaddress).reflectionFromToken(
                toSale,
                false
            );
            IClaimSale(claimContract).addLock(
                msg.sender,
                reflection,
                timeNow + s.lockLength
            );

            numLocks++;
            toSend = toSale;
            // no more for this price
            saleSteps[currentSaleStep].tokenAmount = 0;

            // calculate remaning USD
            dollars = ((tokens - toSale) * 1000000) / s.tokensPerUSD;
            // advance to next sale step
            currentSaleStep++;
            if (currentSaleStep == saleSteps.length) {
                // send tokens to claim contract
                require(
                    IERC20(BigSBaddress).transfer(claimContract, toSend),
                    "Transfer failed"
                );
                // no more steps, refund whats left
                return dollars;
            }
            // recalculate tokens
            tokens =
                (dollars * saleSteps[currentSaleStep].tokensPerUSD) /
                1000000;
        }

        // do not add empty lock
        if (tokens > 0) {
            uint256 amt = IReflect(BigSBaddress).reflectionFromToken(
                tokens,
                false
            );

            saleSteps[currentSaleStep].tokenAmount -= tokens;
            // make user lock
            IClaimSale(claimContract).addLock(
                msg.sender,
                amt,
                saleSteps[currentSaleStep].lockLength + timeNow
            );
            numLocks++;
            toSend += tokens;
        }
        // ensure any lock is added
        require(numLocks > 0, "Nothing sold");
        require(
            IERC20(BigSBaddress).transfer(claimContract, toSend),
            "Transfer failed"
        );
        return 0;
    }

    //
    // Viewers
    //

    /**
        What is current token price?
     */
    function currentPrice() external view returns (uint256) {
        return saleSteps[currentSaleStep].tokensPerUSD;
    }

    /**
        How many tokens left on current price?
    */
    function tokensLeftInStep() external view returns (uint256) {
        if (currentSaleStep < saleSteps.length) {
            return saleSteps[currentSaleStep].tokenAmount;
        } else return 0;
    }

    /**
    Get ETH price from Chainlink.
    @return ETH price in USD with 6 decimals
    */
    function EthPrice() public view returns (uint256) {
        int256 answer;
        (, answer, , , ) = IChainLink(ChainLinkOracle).latestRoundData();
        // answer is 8 decimals, we need 6 as in stablecoins
        return uint256(answer / 100);
    }

    //
    // Rick mode
    //

    // Set claim contract address (once)
    function setClaimContract(address claimAddress) external onlyOwner {
        require(claimContract == address(0), "Already set");
        claimContract = claimAddress;
    }

    /**
        Update sale ratio of next sale step when needed
        Can be only lower than configured on deploy
        @param tokensPerUSD updated ratio
    */
    function updatePrice(uint256 tokensPerUSD) external onlyOwner {
        require(
            tokensPerUSD <= saleSteps[currentSaleStep + 1].maxTokensPerUSD,
            "Too high ratio"
        );
        saleSteps[currentSaleStep + 1].tokensPerUSD = tokensPerUSD;
    }

    /**
        Set AML limit in USD with 6 decimals
    */
    function updateUsdLimit(uint256 limit) external onlyOwner {
        maxDollarsPerUser = limit;
    }

    /**
        Take ETH from contract
    */
    function withdrawEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
        Take any ERC20 from contract (excl BigSB)
    */
    function withdrawErc20(address token) external onlyOwner {
        require(token != BigSBaddress, "Lol, no");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        // use broken IERC20
        IUsdt(token).transfer(owner, balance);
    }

    /// emergency token withdraw possible after 2 years
    function withdrawBigSB(uint256 amt) external onlyOwner {
        require(block.timestamp > saleEnd, "Too soon");
        uint256 balance = IERC20(BigSBaddress).balanceOf(address(this));
        require(amt <= balance, "Too much");
        require(IERC20(BigSBaddress).transfer(owner, amt), "Transfer failed");
    }
}

//This is fine!