/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IFundPool.sol

pragma solidity ^0.6.12;

abstract contract IFundPool {
    function token() external view virtual returns (address);

    function take(uint256 amount) external virtual;

    function getTotalTokensByProfitRate()
        external
        view
        virtual
        returns (
            address,
            uint256,
            uint256
        );

    function profitRatePerBlock() external view virtual returns (uint256);

    function getTokenBalance() external view virtual returns (address, uint256);

    function getTotalTokenSupply()
        external
        view
        virtual
        returns (address, uint256);

    function returnToken(uint256 amount) external virtual;
}

// File: contracts/FundPoolStorage.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;



contract FundPoolAdminStorage is Ownable {
    address public admin;

    address public implementation;
}

abstract contract FundPoolStorgeV1 is FundPoolAdminStorage, IFundPool {
    address public controller; //controller合约(用于管理员统一处理资金池和策略的合约)
    address public feeTo; //手续费地址 包括申购赎回管理费
    address public override token; //资金池币种
    address public weth; //weth地址
    address public sVaultNetValue; //SVaultNetValue地址

    uint256 public totalShares; //持币凭证总量

    uint256 public totalTokenSupply; //申购总额 总本金
    mapping(address => Share) public shares; //用户持币凭证数量及购买时间

    uint256 public tokenAmountLimit; //总投资限额
    uint256 public managementFeeRate; //基金管理费率(从赎回token里扣除，每次充提更新管理费)
    WithdrawFeeRate[] public withdrawFeeRate; //提币手续费数组(从赎回token里扣除，按照时间偏移量倒叙排列，例如30天 0.3%，15天0.8%，7天0.5%，小于7天1.5%)
    uint256 public depositFeeRate; //申购手续费
    // uint256 public max; //除数(用于费率计算) 1e18

    uint256 public override profitRatePerBlock; //每个块的收益率，0为高风险，非0为最高收益率(复利暂时填万2)

    //低风险时参数
    uint256 public minProfitRate; //最低收益率，
    uint256 public maxProfitRate; //最高收益率，
    uint256 public cumulativeProfit; //累计的收益  与本金相加为totalTokens

    uint256 public blockHeightLast; //上次更新的块高

    uint256 public takeAmount; //controller 提取的数量

    struct Share {
        uint256 shareAmount; //份额
        uint256 timestampForManagement; //上次管理费更新时间
        uint256 timestampForDeposit; //上次抵押更新时间  用于获取赎回费率
        uint256 managementFee; //累计的管理费
        uint256 cost; //成本
    }
    struct WithdrawFeeRate {
        uint256 timeOffset; //时间范围差值
        uint256 feeRate; //赎回费率
    }
}

// File: contracts/FundPoolDelegator.sol

pragma solidity ^0.6.12;


contract FundPoolDelegator is FundPoolAdminStorage {
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address _token,
        address _weth,
        address _controller,
        address _sVaultNetValue,
        address _feeTo,
        uint256 _profitRatePerBlock,
        uint256 _tokenAmountLimit,
        uint256 _depositFeeRate,
        address _implementation
    ) public {
        admin = msg.sender;
        delegateTo(
            _implementation,
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,uint256,uint256,uint256)",
                _token,
                _weth,
                _controller,
                _sVaultNetValue,
                _feeTo,
                _profitRatePerBlock,
                _tokenAmountLimit,
                _depositFeeRate
            )
        );
        _setImplementation(_implementation);
    }

    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function _setAdmin(address newAdmin) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data)
        public
        returns (bytes memory)
    {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data)
        public
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) =
            address(this).staticcall(
                abi.encodeWithSignature("delegateToImplementation(bytes)", data)
            );
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }

    receive() external payable {}

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }
}