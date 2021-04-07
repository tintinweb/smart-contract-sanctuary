/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// File: contracts\lib\TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts\interface\INestLedger.sol

/// @dev This interface defines the nest ledger methods
interface INestLedger {

    /// @dev Configuration structure of nest ledger contract
    struct Config {
        
        // nest reward scale(10000 based). 2000
        uint16 nestRewardScale;

        // // ntoken reward scale(10000 based). 8000
        // uint16 ntokenRewardScale;
    }
    
    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Carve reward
    /// @param ntokenAddress Destination ntoken address
    function carveReward(address ntokenAddress) external payable;

    /// @dev Add reward
    /// @param ntokenAddress Destination ntoken address
    function addReward(address ntokenAddress) external payable;

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The ntoken address
    function totalRewards(address ntokenAddress) external view returns (uint);

    /// @dev Pay
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address ntokenAddress, address tokenAddress, address to, uint value) external;

    /// @dev Settlement
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to settle with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address ntokenAddress, address tokenAddress, address to, uint value) external payable;
}

// File: contracts\interface\INestMapping.sol

/// @dev The interface defines methods for nest builtin contract address mapping
interface INestMapping {

    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implemention contract address
    /// @param nestMiningAddress INestMining implemention contract address for nest
    /// @param ntokenMiningAddress INestMining implemention contract address for ntoken
    /// @param nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @param nestVoteAddress INestVote implemention contract address
    /// @param nestQueryAddress INestQuery implemention contract address
    /// @param nnIncomeAddress NNIncome contract address
    /// @param nTokenControllerAddress INTokenController implemention contract address
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;

    /// @dev Set the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implemention contract address
    /// @return nestMiningAddress INestMining implemention contract address for nest
    /// @return ntokenMiningAddress INestMining implemention contract address for ntoken
    /// @return nestPriceFacadeAddress INestPriceFacade implemention contract address
    /// @return nestVoteAddress INestVote implemention contract address
    /// @return nestQueryAddress INestQuery implemention contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implemention contract address
    function getBuiltinAddress() external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );

    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() external view returns (address);

    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() external view returns (address);

    /// @dev Get INestLedger implemention contract address
    /// @return INestLedger implemention contract address
    function getNestLedgerAddress() external view returns (address);

    /// @dev Get INestMining implemention contract address for nest
    /// @return INestMining implemention contract address for nest
    function getNestMiningAddress() external view returns (address);

    /// @dev Get INestMining implemention contract address for ntoken
    /// @return INestMining implemention contract address for ntoken
    function getNTokenMiningAddress() external view returns (address);

    /// @dev Get INestPriceFacade implemention contract address
    /// @return INestPriceFacade implemention contract address
    function getNestPriceFacadeAddress() external view returns (address);

    /// @dev Get INestVote implemention contract address
    /// @return INestVote implemention contract address
    function getNestVoteAddress() external view returns (address);

    /// @dev Get INestQuery implemention contract address
    /// @return INestQuery implemention contract address
    function getNestQueryAddress() external view returns (address);

    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() external view returns (address);

    /// @dev Get INTokenController implemention contract address
    /// @return INTokenController implemention contract address
    function getNTokenControllerAddress() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
}

// File: contracts\interface\INestGovernance.sol

/// @dev This interface defines the governance methods
interface INestGovernance is INestMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}

// File: contracts\NestBase.sol

/// @dev Base contract of nest
contract NestBase {

    constructor() {

        // Temporary storage, used to restrict only the creator to set the governance contract address
        // After setting the address of the governance contract _governance will really represent the contract address
        _governance = msg.sender;
    }

    /// @dev INestGovernance implemention contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implemention contract address
    function update(address nestGovernanceAddress) virtual public {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0));
        _governance = nestGovernanceAddress;
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = INestGovernance(_governance).getNestLedgerAddress();
        if (tokenAddress == address(0)) {
            INestLedger(to).addReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}

// File: contracts\NestLedger.sol

/// @dev Nest ledger contract
contract NestLedger is NestBase, INestLedger {

    /// @param nestTokenAddress Address of nest token contract
    constructor(address nestTokenAddress) {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing from mapping many times
    struct UINT {
        uint value;
    }

    // Configuration
    Config _config;
    // nest ledger
    uint _nestLedger;
    // ntoken ledger
    mapping(address=>UINT) _ntokenLedger;
    // DAO applications
    mapping(address=>uint) _applications;
    // Address of nest token contract
    address immutable NEST_TOKEN_ADDRESS;

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config memory config) override external onlyGovernance {
        require(uint(config.nestRewardScale) <= 10000, "NestLedger:value");
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() override external view returns (Config memory) {
        return _config;
    }

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) override external onlyGovernance {
        _applications[addr] = flag;
    }

    /// @dev Carve reward
    /// @param ntokenAddress Destination ntoken address
    function carveReward(address ntokenAddress) override external payable {

        // nest not carve
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        }
        // ntoken need carve
        else {

            Config memory config = _config;
            UINT storage balance = _ntokenLedger[ntokenAddress];

            // Calculate nest reward
            uint nestReward = msg.value * uint(config.nestRewardScale) / 10000;
            // The part of ntoken is msg.value - nestReward
            balance.value += msg.value - nestReward;
            // nest reward
            _nestLedger += nestReward;
        }
    }

    /// @dev Add reward
    /// @param ntokenAddress Destination ntoken address
    function addReward(address ntokenAddress) override external payable {

        // Ledger for nest is independent
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        }
        // Ledger for ntoken is in a mapping
        else {
            UINT storage balance = _ntokenLedger[ntokenAddress];
            balance.value += msg.value;
        }
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The ntoken address
    function totalRewards(address ntokenAddress) override external view returns (uint) {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            return _nestLedger;
        }
        return _ntokenLedger[ntokenAddress].value;
    }

    /// @dev Pay
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address ntokenAddress, address tokenAddress, address to, uint value) override external {

        require(_applications[msg.sender] > 0, "NestLedger:!app");

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // nest ledger
            if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                _nestLedger -= value;
            }
            // ntoken ledger
            else {
                UINT storage balance = _ntokenLedger[ntokenAddress];
                balance.value -= value;
            }
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    /// @dev Settlement
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to settle with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address ntokenAddress, address tokenAddress, address to, uint value) override external payable {

        require(_applications[msg.sender] > 0, "NestLedger:!app");

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // nest ledger
            if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                // If msg.value is not 0, add to ledger
                _nestLedger = _nestLedger + msg.value - value;
            }
            // ntoken ledger
            else {
                // If msg.value is not 0, add to ledger
                UINT storage balance = _ntokenLedger[ntokenAddress];
                balance.value = balance.value + msg.value - value;
            }
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // If msg.value is not 0, add to ledger
            if (msg.value > 0) {
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    _nestLedger += msg.value;
                } else {
                    UINT storage balance = _ntokenLedger[ntokenAddress];
                    balance.value += msg.value;
                }
            }
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    } 
}