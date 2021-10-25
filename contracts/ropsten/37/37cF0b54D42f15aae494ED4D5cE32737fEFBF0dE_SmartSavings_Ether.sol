// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Interface to the CEther contract.
import "./CEther.sol";
   
contract SmartSavings_Ether  {
   
    // We'll support up to 10^16 shares actively hold in the contract as a conservative limit:
    //   - Shares in this contract are linked to minted cEther tokens (https://compound.finance/docs/ctokens).
    //   - Given that cEther tokens have 8 decimals, 1 cEther will be represented by 100000000 (10^8) shares.
    //   - Since 1 cEther costs >= 0.02 ether, 10^16 shares will require >= 2 x 10^6 (2 million) ether invested in the contract.
    //   - Shares can be also sold (reducing the supply), so this acts like a soft limit that might be reached several times.
    uint256 public constant MAX_SHARES = 10**16;
 
    // A dev fee of 0.25% will be charged when people buy and sell shares.
    // This value is scaled by 10^4.
    uint256 internal constant SCALED_DEV_RATE = 25;

    // A dividend fee of 0.75% will be charged when people buy and sell shares.
    // This value is scaled by 10^4.
    uint256 internal constant SCALED_DIVIDENDS_RATE = 75;

    // Every time someone buys or sells shares, a dividend fee will be distributed proportionally among shareholders.
    //
    // For example, if there are currently 5 x 10^8 shares and someone buys 1 ether worth of shares, a dividend fee of
    // 0.0075 ether (0.75% x 1 ether) will be distributed equally among these 5 x 10^8 shares existing shares, i.e.,
    // 0.000000000015 ether per share.
    // 
    // A similar logic takes place when someone sells shares: if there are currently 100 x 10^8 shares and 25 x 10^8 shares
    // are sold for 2 ethers, 0.015 ether (0.75% x 2 ethers) will be distributed equally among the remaining 75 x 10^8 shares,
    // i.e., 0.000000000002 ether per share.
    //
    // Consider the case where the contract has 10^14 shares (at least 20K ether invested in it). If someone buys 0.01 ether
    // worth of shares, the contract will try to distribute 0.000075 ether (0.75% x 0.01 ether) as dividends among those 10^14 
    // shares, but dividing 0.000075 ether (or 75 x 10^12 wei) into 10^14 shares would result in 0.75 wei. Since we can only do 
    // integer divisions, 75 x 10^12 wei divided by 10^14 shares would result in 0 wei, with a reminder of 75 x 10^12 wei. So, 
    // in this scenario, the amount of 0.000075 ether wouldn't be actually distributed among the shareholders.
    //
    // So, to avoid too much loss of precision, we'll scale up dividend amounts so that we can properly distribute them even
    // when they're too small compared to the current number of shares. Considering MAX_SHARES (10^16), a scaling factor of
    // 10^8 allow us to properly distribute as little as 0.0000000001 ether as dividends among those shares. So, in the example
    // above, 0.000075 ether would be represented as 7500 scaled ether which could be fully divided by 10^14 shares, resulting
    // in 0.00000000075 scaled ether per share (with 0 as remainder).
    //
    // When withdrawing the actual dividends, we'll unscale dividend amounts, i.e., 0.00000000075 scaled ether per share would
    // be equivalent of 0.0000000000000000075 ether per share, or 7.5 wei per share. Since that the smallest dividend amount that
    // we can support is 1 wei, if some user has 7.5 wei per share to withdraw, only 7 wei per share would be immediately
    // available: the other 0.5 wei would need to be accumulated with additional dividends in order to be available for withdraw.
    uint256 internal constant DIVIDENDS_SCALING_FACTOR = 10**8;

    // To make sure that shareholders can always withdraw their dividends, we'll put a hard limit the max amount of scaled
    // dividends that can be ever distributed in the contract. The reason is that, since we'll rely on arithmetic operations
    // to calculate and distribute those dividends, we don't want to ever run into overflow/underflow errors that could prevent
    // people from acessing their dividends. The simplest way to assure that is by applying good limits.
    //
    // With MAX_SHARES = 10^16, we can assure that we can have up to 10^61 scaled dividends per share without running into
    // overflow errors, since:
    //    - max(int256) = 2^256 - 1 (which slightly bigger than 10^77).
    //    - MAX_SHARES x 10^61 = 10^77.
    //
    // We'll perform operations using int256 -- which holds about [-10^76, 10^76]) -- later, so a safer limit will be <= 10^60.
    //
    // Assuming the case where a user holds MAX_SHARES, with a scaling factor of 8 (DIVIDENDS_SCALING_FACTOR), it would still
    // allow an equivalent of 10^52 dividends in wei (or 10^34 ether) as the total amount of dividends ever distributed per share 
    // in the contract: such limit should never be reached in practice but it provides a safe max value nevertheless.
    uint256 internal constant MAX_SCALED_DIVIDENDS_PER_SHARE = 10**76 / (MAX_SHARES * DIVIDENDS_SCALING_FACTOR);

    // Reference to the cEther contract.
    CEther internal cEther;

    // Total number of shares currently available in the contract.
    uint256 public totalShares;

    // The accumulative amount of dividends (in wei) ever distributed per share, scaled by DIVIDENDS_SCALING_FACTOR.
    // For example, If there are currently 5 x 10^8 shares and someone buys 1 ether worth of shares, a dividend fee of
    // 0.0075 ether (0.75% x 1 ether) will be scaled by 10^8, resulting in 750000 scaled ether, or 75 x 10^22 scaled wei.
    // Then, that scaled amound will be distributed equally among these 5 x 10^8 shares existing shares, resulting in 
    // 15 x 10^14 scaled wei per share so scaledDividendsPerShare will be increased by 15 x 10^14.
    uint256 internal scaledDividendsPerShare; 

    // In each dividend distribution, we can have some undistributed amount due to remainders of integer divisions, even applying
    // the scaling factor.
    //
    // Let's say that we currently have 9 x 10^8 shares in the contract and someone buys 0.11 ether worth of shares. In this case:
    //   - 0.000825 ether (0.75% x 0.11 ether) would be scaled by 10^8 (DIVIDENDS_SCALING_FACTOR), resulting in 82500 scaled ether.
    //   - 82500 scaled ether is equivalent of 82500 x 10^18 scaled wei.
    //   - 82500 x 10^18 scaled wei would be divided by 9 x 10^8 shares, resulting in 9166 x 10^10 scaled wei, with reminder = 6.
    //   - The remainder represents the scaled amount of dividends that couldn't be fully distributed among the 9 x 10^8 shares.
    //
    // We don't want to lose undistributed dividends, so we'll keep track of them here and try distribute them in the future
    // when additional dividends come in.
    uint256 internal undistributedScaledDividends;

    // Keep track of the withdrawable dev fees.
    // This value will be:
    //   - Increased when dev fees are collected after people buy/sell shars.
    //   - Decreased when the contract owner withdraws available fees. 
    uint256 public withdrawableDevFees;

    // Balance of a particular user.
    struct UserBalance {
        // The number of shares currently hold by the user.
        uint256 numberOfShares;

        // Based in https://github.com/ethereum/EIPs/issues/1726:
        //
        // If shares hold by each user were static and never changed, the total amount of dividends ever earned by `user` (in wei) 
        // could be computed with:      
        //
        //   totalDividendsOf(user) = (scaledDividendsPerShare x user.numberOfShares) / DIVIDENDS_SCALING_FACTOR
        //
        // However, `user.numberOfShares` does change when `user` buys or sells shares and so does the the computed value
        // of `scaledDividendsPerShare x user.numberOfShares`. In order to keep `totalDividendsOf(user)` unchanged even in such
        // cases, we need to add a correction term:
        //
        //   totalDividendsOf(user) =
        //       (scaledDividendsPerShare x user.numberOfShares + user.scaledDividendCorrections) / DIVIDENDS_SCALING_FACTOR
        //
        // The value of `user.scaledDividendCorrections` is updated whenever `user.numberOfShares` changes:
        //   - When a user buys  N shares: user.scaledDividendCorrections -= scaledDividendsPerShare x N.
        //   - When a user sells M shares: user.scaledDividendCorrections += scaledDividendsPerShare x M.
        //
        // Note that we may need to store negative corrections, so we're using int256 here (and not uint256).
        int256 scaledDividendCorrections;
        
        // The total amount of dividends withdrawn by the user.
        // This amount is represented in wei (unscaled by DIVIDENDS_SCALING_FACTOR).
        uint256 withdrawnDividends;
    }

    // Contract owner.
    // This account will be able to withdraw the dev fees.
    address payable public contractOwner;

    // Keep track of balances for each user.
    mapping(address => UserBalance) internal balanceOf;

    /**
     * Constructor.
     */
    constructor(address _cEtherContractAddress) {
        // Set the deployer of the contract as the contract owner.
        contractOwner = payable(msg.sender);

        // Set reference to the cEther contract.
        cEther = CEther(_cEtherContractAddress);
    }

    /**
     * Allow the contract to receive ether.
     */
    receive() external payable {
        // We need this to receive ether from Compound after redeeming cEther tokens.
        //
        // This actually allows anyone to send ether directly to this contract, but users *SHOULD NOT* do it, otherwise the sent
        // ether will be lost forever! In order to purchase shares using ether, people should use the buyShares() function instead.
        //
        // We could try to detect when the transfer comes from the cEther contract or from a different address and treat the latter
        // as users buying shares, but that would impose a smart contract risk: if somehow Compound changed the address we receive 
        // ether from -- maybe using an upgradable/proxy contract approach, for example --, the whole logic for selling shares here
        // would be compromised, so we don't do that.
    }

    /**
      * Returns the ether balance available in this contract.
      * 
      * Available balance can be made of:
      *   - Dev fees that haven't been withdrawn yet.
      *   - Dividends that haven't been withdrawn by users yet.
      *   - Dividends that haven't been distributed yet (remainders from previous distributions).
      * 
      * In the case where people send ether directly to this contract, the balance may be also increased by those ether, but they
      * will not be available for anyone -- that's why users should use the buyShares() function instead.
      */ 
    function contractBalance() public view returns (uint256) {
        return address(this).balance;   
    } 

    /**
      * Returns how much wei one share is worth.
      * This value is scaled by 10^18.
      */ 
    function sharePrice() public view returns (uint256) {
        // Shares are directly linked to cEther tokens, so we'll rely on the official exchange rate from Compound.
        //
        // Given that:
        //
        //   - One cEther is represented by 10^8 shares. 
        //   - One cEther = cEther.exchangeRateCurrent() x 10^(-28) ether (https://compound.finance/docs/ctokens#exchange-rate).
        //   - One ether is 10^18 wei.
        //
        // We have: 
        //
        //   - 10^8 shares = scaledExchangeRate_CEther_Ether x 10^(-28) ether.
        //   - 1 share = scaledExchangeRate_CEther_Ether x 10^(-36) ether.
        //   - 1 share = scaledExchangeRate_CEther_Ether x 10^(-36) x 10^18 wei.
        //   - 1 share = scaledExchangeRate_CEther_Ether x 10^(-18) wei.
        //
        // We can then say that cEther.exchangeRateCurrent() = how much wei one share is worth, scaled by 10^18.
        return cEther.exchangeRateStored();
    }

    /**
      * Allows users to buy shares using ether.
      */ 
    function buyShares() public payable {
        // Sanity checks.
        require (msg.value > 0, "{ERR_001}");
        require (totalShares < MAX_SHARES, "{ERR_002}");

        // Total wei provided by the user.
        uint256 weiAmount = msg.value;

        // Calculate dev fee.
        // That can fail if (weiAmount x SCALED_DEV_RATE) is over 2^256 - 1: should never happen but better safe than sorry.
        (bool success, uint256 scaledDevFee) = tryMul(weiAmount, SCALED_DEV_RATE);        
        require (success, "{ERR_003}");

        // Get the actual dev fee by unscaling the value.
        uint256 devFee = scaledDevFee / (10**4);

        // Collect dev fee.
        // That can fail if (withdrawableDevFees + devFee > 2^256 - 1): should never happen but better safe than sorry.
        // Note: if the addition fails, withdrawableDevFees is left unchanged.
        (success, withdrawableDevFees) = tryAdd(withdrawableDevFees, devFee);
        require (success, "{ERR_003}");

        // Calculate dividends to be distributed.
        // That can fail if (weiAmount x SCALED_DIVIDENDS_RATE) is over 2^256 - 1: should never happen but better safe than sorry.
        uint256 scaledDividendFee;
        (success, scaledDividendFee) = tryMul(weiAmount, SCALED_DIVIDENDS_RATE);        
        require (success, "{ERR_003}");

        // Get the actual dividend fee by unscaling the value.
        uint256 dividendFee = scaledDividendFee / (10**4);

        // Try to distribute the dividends.
        // If we can't distribute dividends, the request will be reverted with relevant error message.
        // Distribution of dividends can fail if:
        //   - There's an integer overflow error (shouldn't really happen, but it's accounted for).
        //   - The maximum amount of dividends that can be handled is reached (shouldn't happen in practice, but it's accounted for). 
        string memory errorMessage;
        (success, errorMessage) = distributeDividends(dividendFee);
        require (success, errorMessage);

        // Determine the final net amount that can be used for buying shares.
        // The operation below cannot underflow since weiAmount > (devFee + dividends).
        uint256 finalWeiAmount = weiAmount - devFee - dividendFee;

        // Get the current supply of cEther before minting new tokens.
        uint256 oldCEtherSupply = cEther.totalSupply();

        // Supply ether to Compound, minting new cEther tokens.
        // We'll suggest 150K gas as a conservative estimate as provided by Compound at https://compound.finance/docs#gas-costs.
        // On failure, this call reverts with a human-readable error message.
        cEther.mint{value: finalWeiAmount, gas: 150000}();

        // Get the new supply of CEther after minting new tokens.
        uint256 newCEtherSupply = cEther.totalSupply();
        
        // After minting tokens, we expect that the new cEther supply is greater than the old one.
        // Although it's possible that user provides so little wei that it won't be possible to buy even one share, that would be
        // an extremly rare case -- the gas costs would be more than the invested amount --, so we don't want to support such scenario.
        require (newCEtherSupply > oldCEtherSupply, "{ERR_004}");

        // Determine the amount of new shares bought.
        // This operation cannot overflow since newCEtherSupply > oldCEtherSupply. 
        uint256 newShares = newCEtherSupply - oldCEtherSupply;

        // Calculate the new number of total of shares.
        // That could fail if (totalShares + numberOfShares) > 2^256 - 1: should never happen but better safer than sorry.
        uint256 newTotalShares;
        (success, newTotalShares) = tryAdd(totalShares, newShares);
        require (success, "{ERR_005}");

        // Make sure that no more than MAX_SHARES exist.
        require (newTotalShares <= MAX_SHARES, "{ERR_005}");

        // Make sure that the new number of shares matches the updated cEther supply hold by this contract.
        require (newTotalShares == cEther.balanceOf(address(this)), "{ERR_006}");

        // Update the number of shares hold by the user.
        // The operation below cannot overflow since:
        //   - totalShares = sum(balanceOf[user_1].numberOfShares, ..., balanceOf[user_n].numberOfShares)
        //   - balanceOf[msg.sender].numberOfShares <= totalShares
        //   - totalShares + newShares <= MAX_SHARES.
        //   - balanceOf[msg.sender].numberOfShares + newShares <= MAX_SHARES.
        //   - MAX_SHARES < max(int256).
        balanceOf[msg.sender].numberOfShares += newShares;

        // Update the total number of shares.
        totalShares = newTotalShares;


        // We need to recall that:
        //
        //   totalDividendsOf(user) =
        //       (scaledDividendsPerShare x user.numberOfShares + user.scaledDividendCorrections) / DIVIDENDS_SCALING_FACTOR
        //
        // With the additional shares, (scaledDividendsPerShare x user.numberOfShares) will make totalDividendsOf(user) return
        // an additional of (scaledDividendsPerShare x newShares) dividends for that user, but such dividends haven't been actually
        // earned by her/him. We need to deduct that amount from user.scaledDividendCorrections to bring totalDividendsOf(user) 
        // back to the previous (and correct) value. 
        //
        // Let's first calculate how many scaled dividends the new shares represent.
        int256 newSharesScaledDividends = int256(scaledDividendsPerShare * newShares);

        // The operation above cannot overflow since:
        //   - newSharesScaledDividends = scaledDividendsPerShare x newShares.
        //   - scaledDividendsPerShare <= MAX_SCALED_DIVIDENDS_PER_SHARE.
        //   - newShares <= MAX_SHARES.
        //   - newSharesScaledDividends <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
        //   - MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES < max(int256).
        //   - newSharesScaledDividends < max(int256).
        //
        // But we'll assert the conversion anyways.
        assert (newSharesScaledDividends >= 0);

        // Now subtract 'newSharesScaledDividends' from user's scaledDividendCorrections.
        //
        // This operation cannot underflow or underflow. We know that:
        //   - scaledDividendsPerShare >= 0.
        //   - user.numberOfShares >= 0.
        //   - scaledDividendsPerShare x user.numberOfShares >= 0.
        //   - scaledDividendsPerShare x user.numberOfShares <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
        //
        // We also know that when N shares are bought:
        //   - scaledDividendsPerShare x user.numberOfShares is increased by (N x scaledDividendsPerShare).
        //   - userBalance.scaledDividendCorrections is decreased by (N x scaledDividendsPerShare).
        //   
        // Finally, when N shares are sold:
        //   - scaledDividendsPerShare x user.numberOfShares is decreased by (N x scaledDividendsPerShare).
        //   - userBalance.scaledDividendCorrections is increased by (N x scaledDividendsPerShare).
        //
        // Let totalScaledDivs = scaledDividendsPerShare x user.numberOfShares.
        // Let MAX_SCALED_DIVS = MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
        //
        // We can then conclude that:
        //   - the value of totalScaledDivs + userBalance.scaledDividendCorrections doesn't change after shares are bought/sold.
        //   - totalScaledDivs starts as 0 and only increases (up to MAX_SCALED_DIVS).
        //   - totalScaledDivs + userBalance.scaledDividendCorrections >= 0.
        //   - totalScaledDivs + userBalance.scaledDividendCorrections <= MAX_SCALED_DIVS.
        //   - If totalScaledDivs = 0, userBalance.scaledDividendCorrections is within [0, MAX_SCALED_DIVS].
        //   - If totalScaledDivs = MAX_SCALED_DIVS, userBalance.scaledDividendCorrections is within within be [-MAX_SCALED_DIVS, 0].
        //   - min(int256) < -MAX_SCALED_DIVS.
        //   - max(int256) > MAX_SCALED_DIVS.
        balanceOf[msg.sender].scaledDividendCorrections -= newSharesScaledDividends;
    }
 
    /**
      * Allows a user to sell shares, getting ether back.
      */ 
    function sellShares(uint256 _sharesToSell) external {
        // Sanity checks.
        require (_sharesToSell > 0, "{ERR_007}");
        require (balanceOf[msg.sender].numberOfShares >= _sharesToSell, "{ERR_008}");

        // Get the current contract balances before redeeming cEther tokens.
        uint256 oldWeiBalance = contractBalance();
        uint256 oldCEtherSupply = cEther.totalSupply();

        // Redeem cEther from Compound, getting ether back.
        // The number of shares used in this contract is directly linked the contract's cEther supply.
        require (cEther.redeem(_sharesToSell) == 0, "{ERR_009}");

        // Get the contract balances after redeeming cEther tokens.
        uint256 newWeiBalance = contractBalance();
        uint256 newCEtherSupply = cEther.totalSupply();

        // We should always get some additional ether after redeeming cEther tokens.
        require (newWeiBalance > oldWeiBalance, "{ERR_010}");

        // Also, after redeeming cEther tokens, the new cEther supply should be less than the old one.
        require (newCEtherSupply < oldCEtherSupply, "{ERR_011}");

        // We should also make sure the supply difference is exactly _sharesToSell.
        // The operation below cannot underflow since oldCEtherSupply > newCEtherSupply.
        require (oldCEtherSupply - newCEtherSupply == _sharesToSell, "{ERR_012}");

        // Update the number of shares hold by the user.
        // The operation below cannot underflow since balanceOf[msg.sender].numberOfShares >= _sharesToSell.
        balanceOf[msg.sender].numberOfShares -= _sharesToSell;

        // Update the total number of shares.
        // The operation below cannot underflow since:
        //   - totalShares = sum(balanceOf[user_1].numberOfShares, ..., balanceOf[user_n].numberOfShares)
        //   - totalShares >= balanceOf[msg.sender].numberOfShares.
        //   - balanceOf[msg.sender].numberOfShares >= _sharesToSell.
        //   - totalShares >= _sharesToSell.
        totalShares -= _sharesToSell;

        // Sanity check:
        // Make sure that the number of shares matches the cEther supply hold in this contract.
        require (totalShares == cEther.balanceOf(address(this)), "{ERR_006}");

        // We need to recall that:
        //
        //   totalDividendsOf(user) =
        //       (scaledDividendsPerShare x user.numberOfShares + user.scaledDividendCorrections) / DIVIDENDS_SCALING_FACTOR
        //
        // With the reduced number of shares, (scaledDividendsPerShare x user.numberOfShares) will make totalDividendsOf(user)
        // return (scaledDividendsPerShare x _sharesToSell) less dividends for that user, but such dividends have been actually
        // earned by her/him. We need to add that amount to user.scaledDividendCorrections to bring totalDividendsOf(user) 
        // back to the previous (and correct) value.
        //
        //Let's first calculate how many scaled dividends the sold shares represent.
        int256 soldSharesScaledDividends = int256(scaledDividendsPerShare * _sharesToSell);

        // The operation above cannot overflow since:
        //   - soldSharesScaledDividends = scaledDividendsPerShare * _sharesToSell)
        //   - scaledDividendsPerShare <= MAX_SCALED_DIVIDENDS_PER_SHARE.
        //   - _sharesToSell <= MAX_SHARES.
        //   - soldSharesScaledDividends <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
        //   - MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES < max(int256).
        //   - soldSharesScaledDividends < max(int256).
        //
        // But we'll assert the conversion anyways.
        assert (soldSharesScaledDividends >= 0);

        // Now add 'soldSharesScaledDividends' to user's scaledDividendCorrections.
        //
        // This operation cannot underflow or underflow. We know that:
        //   - scaledDividendsPerShare >= 0.
        //   - user.numberOfShares >= 0.
        //   - scaledDividendsPerShare x user.numberOfShares >= 0.
        //   - scaledDividendsPerShare x user.numberOfShares <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
        //
        // We also know that when N shares are bought:
        //   - scaledDividendsPerShare x user.numberOfShares is increased by (N x scaledDividendsPerShare).
        //   - userBalance.scaledDividendCorrections is decreased by (N x scaledDividendsPerShare).
        //   
        // Finally, when N shares are sold:
        //   - scaledDividendsPerShare x user.numberOfShares is decreased by (N x scaledDividendsPerShare).
        //   - userBalance.scaledDividendCorrections is increased by (N x scaledDividendsPerShare).
        //
        // Let totalScaledDivs = scaledDividendsPerShare x user.numberOfShares.
        // Let MAX_SCALED_DIVS = MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
        //
        // We can then conclude that:
        // - the value of totalScaledDivs + userBalance.scaledDividendCorrections doesn't change after shares are bought/sold.
        // - totalScaledDivs starts as 0 and only increases (up to MAX_SCALED_DIVS).
        // - totalScaledDivs + userBalance.scaledDividendCorrections >= 0.
        // - totalScaledDivs + userBalance.scaledDividendCorrections <= MAX_SCALED_DIVS.
        // - If totalScaledDivs = 0, userBalance.scaledDividendCorrections can only be within [0, MAX_SCALED_DIVS].
        // - If totalScaledDivs = MAX_SCALED_DIVS, userBalance.scaledDividendCorrections can only be within [-MAX_SCALED_DIVS, 0].
        // - min(int256) < -MAX_SCALED_DIVS.
        // - max(int256) > MAX_SCALED_DIVS.
        balanceOf[msg.sender].scaledDividendCorrections += soldSharesScaledDividends;


        // Determine resulting wei amount after redeeming cEther tokens. 
        // The operation below cannot underflow since newWeiBalance > oldWeiBalance.
        uint256 weiAmount = newWeiBalance - oldWeiBalance;

        // Calculate dev fee.
        // That can fail if (weiAmount x SCALED_DEV_RATE) is over 2^256 - 1.
        // Should never happen but, if it does, better let people withdraw their money without paying the dev fee.
        (bool success, uint256 scaledDevFee) = tryMul(weiAmount, SCALED_DEV_RATE);  
        if (!success) {
            (success,) = payable(msg.sender).call{value: weiAmount}("");
            require (success, "{ERR_013}");
            return;
        }      

        // Get the actual dev fee by unscaling the value.
        uint256 devFee = scaledDevFee / (10**4);

        // Collect dev fee.
        // Should never happen but, if it does, better let people withdraw their money without paying the dev fee.
        // Note: if the addition fails, withdrawableDevFees is left unchanged.
        (success, withdrawableDevFees) = tryAdd(withdrawableDevFees, devFee);
        if (!success) {
            (success,) = payable(msg.sender).call{value: weiAmount}("");
            require (success, "{ERR_014}");
            return;
        }

        // The operation below cannot underflow since weiAmount > devFee.
        uint256 amountMinusDevFees = weiAmount - devFee;

        // Calculate dividends.
        // That can fail if (weiAmount x SCALED_DIVIDENDS_RATE) is over 2^256 - 1.
        // Should never happen but, if it does, better let people withdraw their money without distributing dividends.
        uint256 scaledDividendFee;
        (success, scaledDividendFee) = tryMul(weiAmount, SCALED_DIVIDENDS_RATE);        
        if (!success) {
            // At this point, the dev fee has been already collected, so we need to consider the amount excluding that fee.
            (success,) = payable(msg.sender).call{value: amountMinusDevFees}("");
            require (success, "{ERR_015}");
            return;
        }
        
        // Get the actual dividend fee by unscaling the value.
        uint256 dividendFee = scaledDividendFee / (10**4);

        // Try to distribute dividends.
        // If we can't distribute dividends, better let people still withdraw their money.
        // Distribution of dividends can fail if:
        //   - There's an integer overflow error (shouldn't really happen, but it's accounted for).
        //   - The maximum amount of dividends that can be safely handled is reached (shouldn't in practice, but it's accounted for). 
        string memory errorMessage;
        (success, errorMessage) = distributeDividends(dividendFee);
        if (!success) {
            // At this point, the dev fee has been already collected, so we need to consider the amount excluding that fee.
            (success,) = payable(msg.sender).call{value: amountMinusDevFees}("");
            require (success, "{ERR_016}");
            return;
        }

        // Determine the final net amount that user will receive.
        // The operation below cannot underflow since weiAmount > (devFee + dividends).
        uint256 finalWeiAmount = weiAmount - devFee - dividendFee;

        // At this point, we've already updated the user balance, we've already taken the dev fee and distributed the dividends
        // among the shareholders. The only thing left to do is transfering funds to the user, so we've also applied
        // the checks-effects-interactions pattern to avoid reentrancy attacks here.
        (success,) = payable(msg.sender).call{value: finalWeiAmount}("");
        require (success, "{ERR_017}");
    }

    /**
     * Distribute dividends (in wei) among shareholders in a proportional manner.
     *
     * If there there are 10 x 10^8 shares in total:
     *    - User 1 has 2 x 10^8 shares.
     *    - User 2 has 4 x 10^8 shares.
     *    - User 3 has 4 x 10^8 shares.
     *
     * Distributing 0.0075 ether (or 75 x 10^14 wei) as dividends will result in:
     *   - User A getting 20% of the dividends, i.e., 0.0015 ether (15 x 10^14 wei).
     *   - User B getting 30% of the dividends, i.e., 0.0030 ether (30 x 10^14 wei).
     *   - User B getting 30% of the dividends, i.e., 0.0030 ether (30 x 10^14 wei).
     */
    function distributeDividends(uint256 _dividends) internal returns (bool, string memory) {
        // No need to try to distribute dividends if they're zero: assume we're done.
        if (_dividends == 0) {
            return (true, "");
        }
        
        // That could fail if (_dividends x DIVIDENDS_SCALING_FACTOR) > 2^256 - 1.
        // Should never happen but better safer than sorry.
        (bool success, uint256 scaledDividends) = tryMul(_dividends, DIVIDENDS_SCALING_FACTOR);
        if (!success) {
            return (false, "{ERR_018}");
        }
        
        // If there are no shares, we can't distribute the dividends yet, so keep them available for the next distribution.
        if (totalShares == 0) {
            // That could fail if (undistributedScaledDividends + scaledDividends) > 2^256 - 1.
            // Should never happen but better safer than sorry.
            // Note: if the addition fails, undistributedScaledDividends is left unchanged.
            (success, undistributedScaledDividends) = tryAdd(undistributedScaledDividends, scaledDividends);
            if (!success) {
                return (false, "{ERR_019}");
            } else {
                // We're done.
                return (true, "");
            }
        }

        // There's at least 1 share in the contract, so we can distribute all dividends available.
        // That could fail if (scaledDividends + undistributedScaledDividends) > 2^256 - 1.
        // Should never happen but better safer than sorry.
        (success, scaledDividends) = tryAdd(scaledDividends, undistributedScaledDividends);
        if (!success) {
            return (false, "{ERR_020}");
        }

        // Calculate how many scaled dividends we should increase per share and also the new undistributed amount (also scaled).
        // No division by zero can happen since totalShares > 0.
        uint256 additionalScaledDividendsPerShare = scaledDividends / totalShares;
        uint256 newUndistributedScaledDividends = scaledDividends % totalShares;

        // Calculate the new the scaled dividends per share.
        // That could fail if (scaledDividendsPerShare + additionalScaledDividendsPerShare) > 2^256 - 1.
        // Realistically, that should never happen, specially with the limit put just below.
        uint256 newScaledDividendsPerShare;
        (success, newScaledDividendsPerShare) = tryAdd(scaledDividendsPerShare, additionalScaledDividendsPerShare);
        if (!success) {
            return (false, "{ERR_021}");
        }

        // Assure that we're still under the safe limit of scaled dividends.
        if (newScaledDividendsPerShare > MAX_SCALED_DIVIDENDS_PER_SHARE) {
            return (false, "{ERR_022}");
        }
        
        // Update state.
        scaledDividendsPerShare = newScaledDividendsPerShare;
        undistributedScaledDividends = newUndistributedScaledDividends;

        // We're done.
        return (true, "");
    }

    /**
     * Returns the total amount of dividends in wei that a user has ever earned.
     * In order to return a value in wei, we need to unscale by DIVIDENDS_SCALING_FACTOR: it may result in values < 1 wei,
     * meaning that the contract hasn't distributed enough dividends to be reflected in the user balance. Eventually, as more 
     * dividends come in, all the accumulative amount will be accounted for.
     */
    function totalDividendsOf(address _user) public view returns(uint256) {
      // Get user balance.
      UserBalance storage userBalance = balanceOf[_user];

      // The multiplication below cannot overflow since:
      //   - totalScaledDividends = scaledDividendsPerShare x userBalance.numberOfShares.
      //   - scaledDividendsPerShare <= MAX_SCALED_DIVIDENDS_PER_SHARE.
      //   - userBalance.numberOfShares <= MAX_SHARES.
      //   - totalScaledDividends <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
      //   - MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES < max(uint256).
      //   - totalScaledDividends < max(uint256).
      uint256 totalScaledDividends = scaledDividendsPerShare * userBalance.numberOfShares;
 
      // We need to convert the totalScaledDividends to int256 in order to apply dividend corrections (which may negative). 
      int256 totalScaledDividendsInt256 = int256(totalScaledDividends);

      // No conversion errors can happen here since:
      //  - totalScaledDividends <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
      //  - MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES < max(int256).
      //  - totalScaledDividends < max(int256).
      //
      // But we'll assert the conversion anyways.
      assert (totalScaledDividendsInt256 >= 0);

      // We then apply the dividend corrections. The operation below cannot overflow or underflow.    
      //
      // This operation cannot underflow or underflow. We know that:
      //   - scaledDividendsPerShare >= 0.
      //   - user.numberOfShares >= 0.
      //   - scaledDividendsPerShare x user.numberOfShares >= 0.
      //   - scaledDividendsPerShare x user.numberOfShares <= MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
      //
      // We also know that when N shares are bought:
      //   - scaledDividendsPerShare x user.numberOfShares is increased by (N x scaledDividendsPerShare).
      //   - userBalance.scaledDividendCorrections is decreased by (N x scaledDividendsPerShare).
      //   
      // Finally, when N shares are sold:
      //   - scaledDividendsPerShare x user.numberOfShares is decreased by (N x scaledDividendsPerShare).
      //   - userBalance.scaledDividendCorrections is increased by (N x scaledDividendsPerShare).
      //
      // Let totalScaledDivs = scaledDividendsPerShare x user.numberOfShares.
      // Let MAX_SCALED_DIVS = MAX_SCALED_DIVIDENDS_PER_SHARE x MAX_SHARES.
      //
      // We can then conclude that:
      //   - the value of totalScaledDivs + userBalance.scaledDividendCorrections doesn't change after shares are bought/sold.
      //   - totalScaledDivs starts as 0 and only increases (up to MAX_SCALED_DIVS).
      //   - totalScaledDivs + userBalance.scaledDividendCorrections >= 0.
      //   - totalScaledDivs + userBalance.scaledDividendCorrections <= MAX_SCALED_DIVS.
      //   - If totalScaledDivs = 0, userBalance.scaledDividendCorrections is within [0, MAX_SCALED_DIVS].
      //   - If totalScaledDivs = MAX_SCALED_DIVS, userBalance.scaledDividendCorrections is within within be [-MAX_SCALED_DIVS, 0].
      //   - min(int256) < -MAX_SCALED_DIVS.
      //   - max(int256) > MAX_SCALED_DIVS.
      int256 correctedTotalDividendsInt256 = totalScaledDividendsInt256 + userBalance.scaledDividendCorrections;
      assert (correctedTotalDividendsInt256 >= 0);

      // Return dividends available in wei.
      // This operation cannot underflow since correctedTotalDividendsInt256 >= 0.
      return uint256(correctedTotalDividendsInt256) / DIVIDENDS_SCALING_FACTOR;
    }


    /**
     * Returns the amount of dividends (in wei) that a user has ever withdrawn.
     */
    function withdrawnDividendsOf(address _user) public view returns (uint256) {
      return balanceOf[_user].withdrawnDividends;
    }

    /**
     * Returns the amount of dividends (in wei) that a user can withdraw (or re-invest).
     */
    function withdrawableDividendsOf(address _user) public view returns (uint256) {
        // The operation below cannot underflow since:
        //   - totalDividendsOf(_user) >= 0.
        //   - withdrawnDividendsOf(_user) >= 0.
        //   - totalDividendsOf(_user) <= MAX_SHARE x MAX_SCALED_DIVIDENDS_PER_SHARE. 
        //   - withdrawnDividendsOf(_user) <= totalDividendsOf(_user).
        return totalDividendsOf(_user) - withdrawnDividendsOf(_user);
    }

    /**
     * Allows the contract owner to withdraw dev fees.
     */
    function withdrawDevFees() public {
        // Permission check.
        require (msg.sender == contractOwner, "{ERR_023}");

        // Update withdrawable fees: use checks-effects-interactions pattern to avoid reentrancy attacks.
        uint256 amount = withdrawableDevFees;
        withdrawableDevFees = 0;

        // Transfer fees to the contract owner.
        (bool success,) = contractOwner.call{value: amount}("");
        require (success, "{ERR_024}");
    }

    /**
     * Allows users to withdraw their dividends.
     */
    function withdrawDividends(uint256 _amount) public {
        // Sanity checks.
        require (_amount > 0, "{ERR_025}");
        uint256 withdrawableDividends = withdrawableDividendsOf(msg.sender);
        require (withdrawableDividends >= _amount, "{ERR_026}");

        // Update withdrawn dividends: use checks-effects-interactions pattern to avoid reentrancy attacks.
        // The operation below cannot overflow since:
        //   - withdrawableDividendsOf(msg.sender) = totalDividendsOf(msg.sender) - balanceOf[msg.sender].withdrawnDividends.
        //   - balanceOf[msg.sender].withdrawnDividends = totalDividendsOf(msg.sender) - withdrawableDividendsOf(msg.sender).
        //   - balanceOf[msg.sender].withdrawnDividends + withdrawableDividendsOf(msg.sender) = totalDividendsOf(msg.sender).
        //   - _amount <= withdrawableDividendsOf(msg.sender).
        //   - balanceOf[msg.sender].withdrawnDividends + _amount <= totalDividendsOf(msg.sender)
        balanceOf[msg.sender].withdrawnDividends += _amount;  

        // Transfer dividends to the user.
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require (success, "{ERR_027}");
    }

    /** 
     * Returns the status for the user calling this function.
     */
    function status() external view
        returns (
            uint256, // Current number of shares hold by the user.
            uint256, // Share price (in wei) scaled by 10^18.
            uint256, // User's holding power (user.numberOfShares / totalShares) scaled by 10^4.
            uint256  // User's available dividends (in wei).
        )
    {
        // Get reference to the caller's balance.
        UserBalance storage userBalance = balanceOf[msg.sender];
        
        // Cannot divide by zero.
        uint256 holdingPower = 0;
        if (totalShares > 0) {
            // The multiplication here cannot overflow since:
            //   - userBalance.numberOfShares x 10^4 <= MAX_SHARES x 10^4.
            //   - MAX_SHARES x 10^4 < max(uint256).
            //   - userBalance.numberOfShares x 10^4 < max(uint256).
            holdingPower = ((userBalance.numberOfShares * (10**4)) / totalShares);
        }

        return (
            userBalance.numberOfShares,
            sharePrice(),
            holdingPower,
            withdrawableDividendsOf(msg.sender)
        );
    }

    /**
     * Returns the multiplication of two unsigned integers, with a success flag (no overflow).
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, a); // return first operand in case of overflow.
            return (true, c);
        } 
    }

    /*
     * Returns the addition of two unsigned integers, with a success flag (no overflow).
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, a); // return first operand in case of overflow.
            return (true, c);
        }
    }
}