/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: GPL 3.0

pragma solidity >= 0.8.4;

interface IErc20 {
    function approve(address, uint256) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


interface ICErc20 {
    function mint(uint256) external returns (uint256);
    function redeemUnderlying(uint) external returns (uint);
    function balanceOfUnderlying(address account) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

interface IComptroller {
    function claimComp(address holder) external;
}

interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (address);
}

interface ILendingPool {
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode ) external;
  function withdraw(address asset, uint256 amount, address to) external;
}

interface ICurvePool {
    function exchange(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount) external;
    function get_dy(int128 from, int128 to, uint256 _from_amount) external view returns (uint256);
}

interface IUniswap {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IUniQuote {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
}

interface IAaveRewards {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256); // deleted override
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256); // deleted override
}

interface IAaveStaked {
    function redeem(address to, uint256 amount) external;
    function cooldown() external;
}

struct TransferTx {
    uint txID;
    uint32 accountNumber;
    address destination;
    uint256 value;
}

struct OwnerTx {
    uint txID;
    uint16 action;
    address owner;
    bytes32 ownerUsername;
    uint16 newThreshold;
    bool exceptionEligible;
}

/// @title BlxmPool
contract BlxmPool {

    modifier onlyManager() {
        require(isManager[msg.sender]);
        _;
    }

    modifier onlyOwner(uint32 accountNumber) {
        require(owners[msg.sender] == accountNumber);
        _;
    }

    modifier ownerOrManager(uint32 accountNumber) {
        require(owners[msg.sender] == accountNumber || isManager[msg.sender]);
        _;
    }

    modifier notNull(address addrs) {
        require(addrs != address(0));
        _;
    }

    modifier accountExists(uint32 accountNumber) { 
        require(accountThreshold[accountNumber] != 0); // a valid account threshold can't be 0
        _;
    }

    modifier managerExists(address manager) {
        require(isManager[manager]);
        _;
    }

    modifier managerDoesNotExist(address manager) {
        require(!isManager[manager]);
        _;
    }

    modifier pendingTransferExists(uint32 accountNumber) {
        require(accountPendingTransfer[accountNumber].length == 1);
        _;
    }

    // events
    event EtherDeposit(uint indexed timestamp, address indexed sender, uint value);
    event Deposit(uint32 indexed accountNumber, uint indexed timestamp, address indexed sender, uint value);
    event Revocation(uint32 indexed accountNumber, uint indexed timestamp, uint indexed transactionId, address sender);
    event Transfer(uint32 indexed accountNumber, uint indexed timestamp, uint indexed transactionId, address destination, uint value);
    event OwnerAddition(uint32 indexed accountNumber, uint indexed timestamp, uint indexed transactionId, address owner);
    event OwnerRemoval(uint32 indexed accountNumber, uint indexed timestamp, uint indexed transactionId, address owner);
    event RequiredSignaturesChange(uint32 indexed accountNumber, uint indexed timestamp, uint indexed transactionId, uint16 oldRequired, uint16 newRequired);

    // contracts we use
    address constant aDai = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address constant aUsdc = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address constant cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address constant cUsdc = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address constant compoundComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address constant aaveAddressesProvider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address constant aaveRewardsContract = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    address constant aaveStakedContract = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    address constant uniswapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant uniswapQuoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    address constant curve3Pool=0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    
    // uniswap paths
    uint24 constant uniswapFee = 3000;
    bytes constant compPath = abi.encodePacked(comp,uniswapFee,weth,uniswapFee,usdc);
    bytes constant aavePath = abi.encodePacked(aave,uniswapFee,weth,uniswapFee,usdc);
    
    // set in constructor
    address aaveLendingPool; 
    mapping (address => int128) curveIndices;
    mapping (address => uint) toDecimals;

    // accounts & owners
    uint32 private accountNumberSeed = 1000000;
    mapping (address => uint32) public owners;
    mapping (uint32 => address[]) accountHolders;
    mapping (uint32 => bytes32[]) accountUserNames;
    mapping (uint32 => uint16) public accountThreshold;
    mapping (uint32 => address) public accountRedemptionAddress;
    mapping (uint32 => uint) accountTransactionCount;
    mapping (uint32 => TransferTx[]) accountPendingTransfer; // array so we can check for existence easily
    mapping (uint32 => OwnerTx[]) accountPendingOwnerTx;
    mapping (uint32 => uint) public accountBalance; // accountNumber => blxm coin
    mapping (uint32 => mapping(uint => address[])) confirmedBy; // accountNumber => txID => address[]

    // managers
    mapping (address => bool) public isManager;
    uint16 managementFee;
    uint32 managementAccount;
    uint public managementFeeLast;

    // holdings
    uint32[] public pendingTransfers; // account numbers with confirmed pending transfers
    uint public totalCoins;

    // retiring
    bool public deactivated=false;

    // fallback() function allows to deposit ether. fallback() is called when calldata is NOT empty and no other method is matched
    fallback() external payable {
        if (msg.value > 0)
            // handle case where msg.sender is not a known owner
            emit EtherDeposit(block.timestamp, msg.sender, msg.value);
    }

    // receive() function allows to deposit ether. receive() is called when calldata is empty
    receive() external payable {
        if (msg.value > 0)
            emit EtherDeposit(block.timestamp, msg.sender, msg.value);
    }

    function refund(address dest) external onlyManager {
        (bool ret,) = dest.call{ value: address(this).balance }("");
        require(ret);
    }

    constructor(address[] memory mngr, bytes32[] memory mngrUserNames, address mngExternalAccount, uint16 fee) {        
        require(mngr.length!=0);
        
        for (uint i=0; i<mngr.length; i++) {
            require(!isManager[mngr[i]] && mngr[i] != address(0));
            isManager[mngr[i]] = true;
        }

        totalCoins = 0;

       ////////// aaveLendingPool = ILendingPoolAddressesProvider(aaveAddressesProvider).getLendingPool();
        curveIndices[dai] = 0;
        curveIndices[usdc] = 1;
        toDecimals[usdc] = 1e6;
        toDecimals[dai] = 1e18;

        managementFee = fee;
        managementAccount = createAccount(mngr, mngrUserNames, 1, mngExternalAccount);
        managementFeeLast = 0;
    }

    // need to confirm with circle that redemptionDestination address is not transient (that would be the redemptionDestination)
    function createAccount(address[] memory ownerAddresses, bytes32[] memory ownerUserNames, uint16 requiredSignatures, address redemptionDestination) public onlyManager returns (uint32) {
        require(requiredSignatures != 0 && ownerAddresses.length==ownerUserNames.length && redemptionDestination!=address(0));

        accountNumberSeed++;
        uint32 accountNumber = accountNumberSeed;

        for (uint i=0; i<ownerAddresses.length; i++) {
            // check for duplicated names and 0 addresses
            require(ownerAddresses[i] != address(0) && owners[ownerAddresses[i]]==0);
            // note this means no more than 1 account per owner (==address)
            owners[ownerAddresses[i]] = accountNumber;
        }

        accountHolders[accountNumber] = ownerAddresses;
        accountUserNames[accountNumber] = ownerUserNames;
        accountThreshold[accountNumber] = requiredSignatures;
        accountRedemptionAddress[accountNumber] = redemptionDestination;
        accountTransactionCount[accountNumber] = 0;

        accountBalance[accountNumber] = 0;

        return accountNumber;
    }

    function deleteAccount(uint32 accountNumber) external onlyManager returns (bool) {
        require(accountBalance[accountNumber] == 0);

        accountUserNames[accountNumber] = new bytes32[](0);
        accountThreshold[accountNumber] = 0;
        accountRedemptionAddress[accountNumber] = address(0);
        accountTransactionCount[accountNumber] = 0;

        address[] memory holders = accountHolders[accountNumber];
        for (uint i=0; i<holders.length; i++) {
            owners[holders[i]] = 0;
        }
        accountHolders[accountNumber] = new address[](0);

        return true;
    }

    function accrueFee() external onlyManager returns (bool) {
        require (managementFeeLast != 0);

        uint blocks = (block.timestamp - managementFeeLast) / 2592000;
        if (blocks >= 1) {
            uint newCoins = totalCoins * blocks * managementFee / (1e4 - blocks * managementFee);
            accountBalance[managementAccount] += newCoins;
            totalCoins += newCoins;
            managementFeeLast += blocks * 2592000;
            return true;
        }

        return false;
    }

    function startFee() external onlyManager {
        require(managementFeeLast == 0);

        managementFeeLast = block.timestamp;
    }

    function setDeactivated() external onlyManager {
        deactivated = true;
    }

    function unsetDeactivated() external onlyManager {
        deactivated = false;
    }

    // sender is most likely msg.sender . keeping some flexibility for now
    function deposit(uint32 accountNumber, uint amount, address sender) external accountExists(accountNumber) returns(uint) {
        // set minimum deposit???
        require(amount != 0 && !deactivated);

        // can only deposit usdc. amount is in USDC scaled to 6 decimals. usdc has 6 decimals. sender is the address holding the usdc balance that set the allowance and approved the transfer for us
        bool ret = IErc20(usdc).transferFrom(sender, address(this), amount);
        require(ret);

        // total pool holdings + accrued rewards on aave and compound valued in usd based on prices on uniswap and curve
        uint[] memory bals = updatePoolHoldings();
        uint rewardsFromTokens = uniQuoteRewards();
        // currentPoolBalance includes the newly deposited amount (after call to transferFrom()). we give blxm token 6 decimals
        uint currentPoolBalance = getPoolBalanceUSD(bals) * 1e6 + rewardsFromTokens;  
        uint newCoins = currentPoolBalance != amount ? amount * totalCoins / (currentPoolBalance-amount) : amount;
        accountBalance[accountNumber] += newCoins;
        totalCoins += newCoins;

        emit Deposit(accountNumber, block.timestamp, msg.sender, amount / 1e6);

        return newCoins;
    }

    function getPoolBalanceUSD(uint[] memory bals) public view returns (uint) {
        // all these are already scaled by 1e18
        uint totalDai = bals[4] + bals[2] + bals[0];

        // usdc is our numeraire and usdc = usd. evaluate the others. daiUsd has 6 decimals (usdc output)
        ICurvePool curvePool = ICurvePool(curve3Pool);
        uint daiUsd = totalDai!=0 ? curvePool.get_dy(curveIndices[dai], curveIndices[usdc], totalDai) : 0;

        uint balance = bals[1] + bals[3] + bals[5] + daiUsd;

        // return in USD
        return balance / 1e6;
    }

    function getPoolHoldings() public view returns (uint[] memory) {
        // get compound deposits. balanceOfUnderlying() changes state. getAccountSnapshot() is view only and returns the exchangeRate from the last interest accrual. cTokens are active enough that exchangeRate will be up-to-date or very close to that: returns are (error_code, deposits, borrows, exchange_rate)
        uint cdaiB = 0;
        uint cusdcB = 0;
        // cdaiB is dai balance on compound, cCdaiB is cdai balance on compound. similar for usdc. exchangeRate/1e18 * ctoken*1e^ctokenDecimals = underlying*1e^underlyingDecimals. ctoken and underlying are the unit values (the unscaled values) 
        (, uint cCdaiB,, uint exchangeRateD) = ICErc20(cDai).getAccountSnapshot(address(this));
        cdaiB = cCdaiB * exchangeRateD / 1e18;
        (, uint cCusdcB,, uint exchangeRateU) = ICErc20(cUsdc).getAccountSnapshot(address(this));
        cusdcB = cCusdcB * exchangeRateU / 1e18;

        (uint adaiB, uint ausdcB, uint daiB, uint usdcB) = nonCompoundHoldings();

        // returned balances are scaled by 1e^decimals, each its own decimals. these CANNOT be changed without breaking client code
        uint[] memory ret = new uint[](6);
        ret[0] = cdaiB;
        ret[1] = cusdcB;
        ret[2] = adaiB;
        ret[3] = ausdcB;
        ret[4] = daiB;
        ret[5] = usdcB;

        return ret;
    }

    // this is state changing because it forces compound to update accrued interest
    function updatePoolHoldings() public returns (uint[] memory) {
        uint cdaiB = ICErc20(cDai).balanceOfUnderlying(address(this));
        uint cusdcB = ICErc20(cUsdc).balanceOfUnderlying(address(this));

        (uint adaiB, uint ausdcB, uint daiB, uint usdcB) = nonCompoundHoldings();

        // returned balances are scaled by 1e^decimals, each its own decimals. these CANNOT be changed without breaking client code
        uint[] memory ret = new uint[](6);
        ret[0] = cdaiB;
        ret[1] = cusdcB;
        ret[2] = adaiB;
        ret[3] = ausdcB;
        ret[4] = daiB;
        ret[5] = usdcB;

        return ret;
    }

    // all up-to-date values of holdings can be obtained with a view function except for compound
    function nonCompoundHoldings() internal view returns (uint, uint, uint, uint) {
        // get aave deposits. note that adai and dai have the same value (same for ausdc and usdc)
        uint adaiB = IErc20(aDai).balanceOf(address(this)); 
        uint ausdcB = IErc20(aUsdc).balanceOf(address(this));

        // get usdc and dai uninvested holdings
        uint usdcB = IErc20(usdc).balanceOf(address(this));
        uint daiB = IErc20(dai).balanceOf(address(this));

        return (adaiB, ausdcB, daiB, usdcB);
    }

    function getAccountBalanceUSD(uint32 accountNumber) external view returns (uint) {
        uint poolBalance = getPoolBalanceUSD(getPoolHoldings());
        uint accountTokens = accountBalance[accountNumber];
        
        // returned value should be in USD
        return totalCoins != 0 ? accountTokens * poolBalance / totalCoins: 0;
    }

    /// manager only for adding so we can test validity of owner address. not a concern for removing an owner
    function submitOwnerTransaction(uint32 accountNumber, uint16 action, address owner, bytes32 ownerUsername, uint16 newThreshold) external onlyManager returns (bool) {
        if (action != 3) {
            require(owner != address(0));
        }
        
        // look for owner
        bool found = false;
        for (uint i=0; i<accountHolders[accountNumber].length; i++) {
            if (accountHolders[accountNumber][i] == owner) {
                found = true;
                break;
            }
        }

        if (action == 1) {
            // owner is being added. we verify owner does not exist
            require(!found);
        } else if (action == 2) {
            // owner is being removed. we verify owner exists and that this is not the last owner
            require(found && accountHolders[accountNumber].length > 1);
        } else if (action == 3) {
            // account threshold is being changed
            uint numOwners = accountHolders[accountNumber].length;
            require(newThreshold >= 1 && newThreshold <= numOwners);
            bool one = true;
            for (uint i=0; i<accountPendingOwnerTx[accountNumber].length; i++){
                if (accountPendingOwnerTx[accountNumber][i].action == 3) {
                    one = false;
                    break;
                }
            }
            // don't allow more than one pending threshold change tx
            require(one);
        }

        accountTransactionCount[accountNumber]++;
        OwnerTx memory ownerTx = OwnerTx({
            txID: accountTransactionCount[accountNumber],
            action: action,
            owner: owner,
            ownerUsername: ownerUsername,
            newThreshold: newThreshold,
            exceptionEligible: false
        });

        accountPendingOwnerTx[accountNumber].push(ownerTx);

        return true;
    }

    function submitTransfer(uint32 accountNumber, uint amount, address destination) external onlyOwner(accountNumber) returns(bool) {
        require(accountPendingTransfer[accountNumber].length == 0);

        uint[] memory bals = updatePoolHoldings();
        uint rewardsFromTokens = uniQuoteRewards();
        uint pool = getPoolBalanceUSD(bals) + rewardsFromTokens / 1e6;
        uint bal = accountBalance[accountNumber]; // these are the blxm tokens held in account
        require(bal != 0);

        uint balUSD = bal * pool / totalCoins;
        // if amount is greater than balance, return entire balance
        if (amount > balUSD) {
            amount = balUSD;
        }

        if (destination == address(0)) {
            destination = accountRedemptionAddress[accountNumber];
        }

        accountTransactionCount[accountNumber]++;
        TransferTx memory transferTx = TransferTx({
            txID: accountTransactionCount[accountNumber],
            accountNumber: accountNumber,
            destination: destination,
            value: amount
        });

        accountPendingTransfer[accountNumber].push(transferTx);
        // owner who submitted transfer automatically confirms
        return confirmTransferInternal(accountNumber, transferTx.txID, msg.sender);
    }

    function confirmOwnerTx(uint32 accountNumber, uint txID) external onlyOwner(accountNumber) accountExists(accountNumber) returns(bool) {
        bool found = false;
        for (uint i=0; i<accountPendingOwnerTx[accountNumber].length; i++) {
            if (accountPendingOwnerTx[accountNumber][i].txID == txID) { // matching txID ensures the right owner change is being confirmed and that txID was indeed submitted
                found = true;
                break;
            }
        }

        if (found) {
            if (!checkConfirmation(confirmedBy[accountNumber][txID], msg.sender)){
                confirmedBy[accountNumber][txID].push(msg.sender);
            }

            if (confirmedBy[accountNumber][txID].length == accountThreshold[accountNumber]) {
                require(executeOwnerTx(accountNumber, txID));
            }

            return true;
        }

        return false; // txID not found
    }

    function confirmTransfer(uint32 accountNumber, uint txID) external onlyOwner(accountNumber) accountExists(accountNumber) returns(bool) {
        require(accountPendingTransfer[accountNumber].length == 1);

        return confirmTransferInternal(accountNumber, txID, msg.sender);
    }

    function confirmTransferInternal(uint32 accountNumber, uint txID, address sender) internal returns(bool) {
        if (accountPendingTransfer[accountNumber][0].txID == txID)  { // sanity check. added protection against double transfer if we have a stale enrty in confirmedBY
            if (!checkConfirmation(confirmedBy[accountNumber][txID], sender)) {
                confirmedBy[accountNumber][txID].push(sender); // sender already confirmed. we return normally
            }

            if (confirmedBy[accountNumber][txID].length == accountThreshold[accountNumber]) {
                bool alreadyIn = false;
                for (uint i=0; i<pendingTransfers.length; i++) {
                    if (pendingTransfers[i] == accountNumber) {
                        alreadyIn = true;
                        break;
                    }
                }
                if (!alreadyIn) pendingTransfers.push(accountNumber); // ready to execute
            }

            return true;
        }

        return false; // txID is wrong
    }

    function checkConfirmation(address[] memory alreadyConfirmed, address newSender) internal pure returns(bool) {
        for (uint i=0; i<alreadyConfirmed.length; i++) {
            if (newSender == alreadyConfirmed[i]) {
                return true;
            }
        }

        return false;
    }

    function revokeTransaction(uint32 accountNumber, uint txID) external onlyManager returns (bool) {
        // transaction could be either: an owner tx or a transfer. Note this gives the manager the power to cancel a transfer, OK????
        bool found = false;

        if (accountPendingTransfer[accountNumber].length == 1 && accountPendingTransfer[accountNumber][0].txID==txID) {
            accountPendingTransfer[accountNumber].pop();
            found = true;
        } else {
            for (uint i=0; i<accountPendingOwnerTx[accountNumber].length; i++) {
                if (accountPendingOwnerTx[accountNumber][i].txID == txID) {
                    accountPendingOwnerTx[accountNumber][i] = accountPendingOwnerTx[accountNumber][accountPendingOwnerTx[accountNumber].length-1]; // can only pop last element in array. so shift last element first
                    accountPendingOwnerTx[accountNumber].pop();
                    found = true;
                    break;
                }
            }
        }

        if (found) {
            emit Revocation(accountNumber, block.timestamp, txID, msg.sender);
        }

        return false; // no matching txID
    }

    /// manager needs to make funds available prior to calling this
    function executeTransfer(uint32 accountNumber) external onlyManager returns (bool) {
        require(accountPendingTransfer[accountNumber].length==1);
        uint txID = accountPendingTransfer[accountNumber][0].txID;

        require(confirmedBy[accountNumber][txID].length >= accountThreshold[accountNumber]);
        
        // we already verified value < user balance when transaction was submitted. the value of blxm coins could have only grown since then
        // get fresh pool balance and calculate coins equivalent to amount being transferred
        uint[] memory bals = updatePoolHoldings();
        uint rewardsFromTokens = uniQuoteRewards();
        uint pool = getPoolBalanceUSD(bals) + rewardsFromTokens / 1e6;
        uint coins = accountPendingTransfer[accountNumber][0].value * totalCoins / pool;
        // This is only violated if between the time transfer was submitted and here transaction fees were paid for swaps
        require(coins <= accountBalance[accountNumber]);
        accountBalance[accountNumber] -= coins;
        totalCoins -= coins;

        // transfer
        bool ret = IErc20(usdc).transfer(accountPendingTransfer[accountNumber][0].destination, accountPendingTransfer[accountNumber][0].value * 1e6);
        emit Transfer(accountNumber, block.timestamp, txID, accountPendingTransfer[accountNumber][0].destination, accountPendingTransfer[accountNumber][0].value);
        require(ret);

        // remove from pending
        accountPendingTransfer[accountNumber].pop();
        for (uint i=0; i<pendingTransfers.length; i++) {
            if (pendingTransfers[i]==accountNumber) {
                pendingTransfers[i] = pendingTransfers[pendingTransfers.length-1];
                pendingTransfers.pop();
            }
        }

        return true;
    }

     /// not external so address(this) can call it
    function executeOwnerTx(uint32 accountNumber, uint txID) public ownerOrManager(accountNumber) returns (bool) {
        for (uint i=0; i<accountPendingOwnerTx[accountNumber].length; i++) {
            OwnerTx memory ownerTx = accountPendingOwnerTx[accountNumber][i];
            if (txID == ownerTx.txID) {
                // remember that if exceptionEligible == true then at least 1 owner has already confirmed
                require(confirmedBy[accountNumber][txID].length >= accountThreshold[accountNumber] || (isManager[msg.sender] && ownerTx.exceptionEligible));

                if (ownerTx.action == 1) { // add owner
                    owners[ownerTx.owner] = accountNumber;
                    accountHolders[accountNumber].push(ownerTx.owner);
                    accountUserNames[accountNumber].push(ownerTx.ownerUsername);

                    emit OwnerAddition(accountNumber, block.timestamp, txID, ownerTx.owner);
                } else if (ownerTx.action == 2) { // remove owner
                    owners[ownerTx.owner] = 0; // there's no removing keys in solidity. mapping to default value does the trick
                    uint l = accountHolders[accountNumber].length; // kept in sync with accountUsernames
                    for (uint j=0; j<l; j++){
                        if (accountHolders[accountNumber][j] == ownerTx.owner) {
                            accountHolders[accountNumber][j] = accountHolders[accountNumber][l-1];
                            accountHolders[accountNumber].pop();
                            accountUserNames[accountNumber][j] = accountUserNames[accountNumber][l-1];
                            accountUserNames[accountNumber].pop();

                            emit OwnerRemoval(accountNumber, block.timestamp, txID, ownerTx.owner);
                            break;
                        }
                    }
                } else if (ownerTx.action == 3) { // new required number of sigs for account
                    uint16 oldThreshold = accountThreshold[accountNumber];
                    accountThreshold[accountNumber] = ownerTx.newThreshold;

                    emit RequiredSignaturesChange(accountNumber, block.timestamp, txID, oldThreshold, ownerTx.newThreshold);
                }

                accountPendingOwnerTx[accountNumber][i] = accountPendingOwnerTx[accountNumber][accountPendingOwnerTx[accountNumber].length - 1];
                accountPendingOwnerTx[accountNumber].pop();

                return true;
            }
        }
        
        return false;
    }

    function setExceptionEligible(uint32 accountNumber, uint txID) external onlyOwner(accountNumber) returns (bool) {
        require(checkConfirmation(confirmedBy[accountNumber][txID], msg.sender));
        
        // transaction can only be an owner tx
        for (uint i=0; i<accountPendingOwnerTx[accountNumber].length; i++) {
            if (accountPendingOwnerTx[accountNumber][i].txID == txID) {
                accountPendingOwnerTx[accountNumber][i].exceptionEligible = true;

                return true;
            }
        }

        return false; // txID was not found
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners(uint32 accountNumber) public view accountExists(accountNumber) returns (address[] memory, bytes32[] memory) {
        return (accountHolders[accountNumber], accountUserNames[accountNumber]);
    }

    function getPendingTransfer(uint32 accountNumber) public view accountExists(accountNumber) returns (uint, address, uint) {
        if (accountPendingTransfer[accountNumber].length !=1) {
            return (0,address(0),0);
        }
        
        TransferTx memory pendingTransfer = accountPendingTransfer[accountNumber][0];
        return (pendingTransfer.txID, pendingTransfer.destination, pendingTransfer.value);
    }
    
    /// returns total USD amount pending to be transferred from all accounts
    function getPendingTransferAmount() public view returns (uint) {
        uint amount = 0;
        for (uint i = 0; i<pendingTransfers.length; i++) {
            // if account number is in pendingTransfers, then account must have a pending transfer. no need to check for existence. returns USD
            amount += accountPendingTransfer[pendingTransfers[i]][0].value;
        }

        return amount;
    }

    function getNumberOfPendingTransfers() public view returns (uint) {
        return pendingTransfers.length;
    }

    function getNumberOfPendingOwnerTx(uint32 accountNumber) public view accountExists(accountNumber) returns (uint) {
        return accountPendingOwnerTx[accountNumber].length;
    }

    function getPendingOwnerTx(uint32 accountNumber, uint ind) public view accountExists(accountNumber) returns (uint, uint16, address, bytes32, uint16) {
        // ind is the index in accountPendingOwnerTx[accountNumber] of the desired transaction
        OwnerTx memory ownerTx = accountPendingOwnerTx[accountNumber][ind];
        return (ownerTx.txID, ownerTx.action, ownerTx.owner, ownerTx.ownerUsername, ownerTx.newThreshold);
    }

    function getTxConfirmations(uint32 accountNumber, uint txID) public view accountExists(accountNumber) returns (address[] memory) {
        return confirmedBy[accountNumber][txID];
    }

    // amounts MUST be already properly scaled to reflect appropriate decimals
    function portfolioActions(uint16[] calldata actions,  uint16[] calldata tokens,  uint256[] calldata amounts) external onlyManager returns (bool) {
        for (uint16 a=0; a < actions.length; a++) {
            if (actions[a] == 3) { // compound deposit
                IErc20 underlying = tokens[a]==1 ? IErc20(usdc) : IErc20(dai);
                address cAddr = tokens[a]==1 ? cUsdc : cDai;
                ICErc20 cTokenContr = ICErc20(cAddr);
                underlying.approve(cAddr, amounts[a]);
                cTokenContr.mint(amounts[a]); // ignoring returned value
            } else if (actions[a] == 1) { // compound withdraw
                ICErc20 cTokenContr = tokens[a]==1 ? ICErc20(cUsdc) : ICErc20(cDai);
                cTokenContr.redeemUnderlying(amounts[a]); // ignoring returned value
            } else if (actions[a] == 4) { // aave deposit
                address underlying = tokens[a]==1 ? usdc : dai;
                IErc20(underlying).approve(aaveLendingPool, amounts[a]);
                ILendingPool(aaveLendingPool).deposit(underlying, amounts[a], address(this), uint16(0));
            } else if (actions[a] == 2) { // aave withdraw
                address underlying = tokens[a]==1 ? usdc : dai;
                ILendingPool(aaveLendingPool).withdraw(underlying, amounts[a], address(this));
            } else {
                return false;
            }
        }

        return true;
    }

    function kill() external onlyManager returns (bool) {
        // liquidate everything on compound, this will automatically give us all accumulated comp
        uint cdaiB = ICErc20(cDai).balanceOfUnderlying(address(this));
        uint cusdcB = ICErc20(cUsdc).balanceOfUnderlying(address(this));
        ICErc20(cDai).redeemUnderlying(cdaiB);
        ICErc20(cUsdc).redeemUnderlying(cusdcB);

        // aave
        ILendingPool(aaveLendingPool).withdraw(dai, type(uint256).max, address(this));
        ILendingPool(aaveLendingPool).withdraw(usdc, type(uint256).max, address(this));

        // swap dai for usdc
        uint totalDai = IErc20(dai).balanceOf(address(this));
        curveSwap(dai, usdc, totalDai);

        // swap comp
        uniswap();

        // stkAave not handled since only withdrawn on a schedule;

        return true;
    }

    function claimRewards(uint16 platform) external onlyManager returns (bool) {
        if (platform !=2) {
            IComptroller(compoundComptroller).claimComp(address(this));
        }
        
        if (platform !=1) {
            address[] memory aTokens = new address[](2);
            aTokens[0] = aUsdc;
            aTokens[1] = aDai;
            IAaveRewards(aaveRewardsContract).claimRewards(aTokens, type(uint256).max, address(this));
            // we can only redeem after a cool down period of 10 days, and then only within 2 datys
            IAaveStaked(aaveStakedContract).cooldown();
        }

        return true;
    }

    function redeemAave() external onlyManager returns (bool) {
        IAaveStaked(aaveStakedContract).redeem(address(this), type(uint256).max);
        return true;
    }

    function uniQuoteRewards() internal returns (uint) {
        uint stkAaveB = 0; 
        IAaveRewards aaveRewards = IAaveRewards(aaveRewardsContract);
        // get accrued reward tokens on aave and compound. Note: this requires Comp to have been claimed
        address[] memory assets = new address[](2);
        assets[0] = dai;
        assets[1] = usdc;
        try aaveRewards.getRewardsBalance(assets, address(this)) returns (uint v) {
            stkAaveB = v;
        } catch (bytes memory) {}
        uint compB = IErc20(comp).balanceOf(address(this));
        uint aaveB = IErc20(aave).balanceOf(address(this));
        IUniQuote quoter = IUniQuote(uniswapQuoter);
        uint comp2Usdc = 0;
        uint aave2Usdc = 0;
        if (compB != 0) {
            comp2Usdc = quoter.quoteExactInput(compPath, compB);
        }
        if (aaveB !=0) {
            aave2Usdc = quoter.quoteExactInput(aavePath, aaveB+stkAaveB);
        }
        
        return comp2Usdc+aave2Usdc;
    }

    function uniswap() public onlyManager returns (uint, uint) {
        uint usdcFromComp = 0;
        // swap comp
        uint256 compB = IErc20(comp).balanceOf(address(this));
        if (compB != 0) {
            IErc20(comp).approve(uniswapRouterV3, compB);

            IUniswap.ExactInputParams memory params = IUniswap.ExactInputParams({
                path: compPath,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: compB,
                amountOutMinimum: 0
            });
            usdcFromComp = IUniswap(uniswapRouterV3).exactInput(params);
        }
        
        uint usdcFromAave = 0;
        // swap aave
        uint256 aaveB = IErc20(aave).balanceOf(address(this));
        if (aaveB != 0) {
            IErc20(aave).approve(uniswapRouterV3, aaveB);

            IUniswap.ExactInputParams memory params = IUniswap.ExactInputParams({
                path: aavePath,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: aaveB,
                amountOutMinimum: 0
            });
            usdcFromAave = IUniswap(uniswapRouterV3).exactInput(params);
        }

        return (usdcFromComp, usdcFromAave);    
    }
    
    function curveSwap(address inErc, address outErc, uint256 amount) public onlyManager returns (bool) {
        ICurvePool curvePool = ICurvePool(curve3Pool);
        uint256 e = curvePool.get_dy(curveIndices[inErc], curveIndices[outErc], amount);
        // sanity check
        if (e * toDecimals[inErc] * 100 < amount * 90 * toDecimals[outErc]) {
            return false;
        }

        IErc20(inErc).approve(curve3Pool, amount);
        curvePool.exchange(curveIndices[inErc], curveIndices[outErc], amount, e * 9995 / 1e4);

        return true;
    }

    function getCurveDy(address inErc, address outErc, uint256 dx) external view returns(uint256) { 
        ICurvePool curvePool = ICurvePool(curve3Pool);
        uint256 dy = curvePool.get_dy(curveIndices[inErc], curveIndices[outErc], dx);
        
        return dy;
    }

    function addManager(address manager) external onlyManager managerDoesNotExist(manager) returns (bool) {
        isManager[manager] = true;
        return true;
    }

    function removeManager(address manager) external onlyManager managerExists(manager) returns (bool) {
        // manager can't remove self guarantees we always have at least one manager
        require(msg.sender != manager);

        isManager[manager] = false;
        return true;
    }

}