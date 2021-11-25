/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// File: browser/polygon/contracts_common/Libraries/BytesUtil.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library BytesUtil {
    function memcpy(uint256 dest, uint256 src, uint256 len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function pointerToBytes(uint256 src, uint256 len)
    internal
    pure
    returns (bytes memory)
    {
        bytes memory ret = new bytes(len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, src, len);
        return ret;
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(
            add(m, 20),
            xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function uint256ToBytes(uint256 a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 32), a)
            mstore(0x40, add(m, 64))
            b := m
        }
    }

    function doFirstParamEqualsAddress(bytes memory data, address _address)
    internal
    pure
    returns (bool)
    {
        if (data.length < (36 + 32)) {
            return false;
        }
        uint256 value;
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint256(uint160(_address));
    }

    function doParamEqualsUInt256(bytes memory data, uint256 i, uint256 value)
    internal
    pure
    returns (bool)
    {
        if (data.length < (36 + (i + 1) * 32)) {
            return false;
        }
        uint256 offset = 36 + i * 32;
        uint256 valuePresent;
        assembly {
            valuePresent := mload(add(data, offset))
        }
        return valuePresent == value;
    }

    function overrideFirst32BytesWithAddress(
        bytes memory data,
        address _address
    ) internal pure returns (bytes memory) {
        uint256 dest;
        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)

        bytes memory addressBytes = addressToBytes(_address);
        uint256 src;
        assembly {
            src := add(addressBytes, 32)
        }

        memcpy(dest, src, 20);
        return data;
    }

    function overrideFirstTwo32BytesWithAddressAndInt(
        bytes memory data,
        address _address,
        uint256 _value
    ) internal pure returns (bytes memory) {
        uint256 dest;
        uint256 src;

        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)
        bytes memory bbytes = addressToBytes(_address);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 20);

        assembly {
            dest := add(data, 68)
        } // 48 = 32 (offset) + 4 (func sig) + 32 (next slot)
        bbytes = uint256ToBytes(_value);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 32);

        return data;
    }
}
// File: browser/polygon/contracts_common/BaseWithStorage/Admin.sol

pragma solidity 0.8.2;

contract Admin {
    address internal _admin;
    event AdminChanged(address oldAdmin, address newAdmin);

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin can change admin");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}

// File: browser/polygon/contracts_common/BaseWithStorage/SuperOperators.sol

pragma solidity 0.8.2;


contract SuperOperators is Admin {
    mapping(address => bool) internal _superOperators;
    event SuperOperator(address superOperator, bool enabled);

    function setSuperOperator(address superOperator, bool enabled) external {
        require(
            msg.sender == _admin,
            "only admin is allowed to add super operators"
        );
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

// File: browser/polygon/contracts_common/Interfaces/ERC20Events.sol

pragma solidity 0.8.2;

contract ERC20Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
    //indexed回允许你在web3.js对加了这个属性的参数进行过滤
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: browser/polygon/contracts_common/BaseWithStorage/ERC20/extensions/ERC20Internal.sol

pragma solidity 0.8.2;

abstract contract ERC20Internal {
    function _approveFor(
        address owner,
        address target,
        uint256 amount
    ) internal virtual;

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual;
}
// File: browser/polygon/contracts_common/BaseWithStorage/ERC20/extensions/ERC20BasicApproveExtension.sol

pragma solidity 0.8.2;

abstract contract ERC20BasicApproveExtension is ERC20Internal {

    /// @notice approve `target` to spend `amount` and call it with data.
    /// @param target address to be given rights to transfer and destination of the call.
    /// @param amount the number of tokens allowed.
    /// @param data bytes for the call.
    /// @return data of the call.
    function approveAndCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(
            BytesUtil.doFirstParamEqualsAddress(data, msg.sender),
            "first param != sender"
        );

        _approveFor(msg.sender, target, amount);

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));
        return returnData;
    }

    /// @notice temporarly approve `target` to spend `amount` and call it with data. Previous approvals remains unchanged.
    /// @param target destination of the call, allowed to spend the amount specified
    /// @param amount the number of tokens allowed to spend.
    /// @param data bytes for the call.
    /// @return data of the call.
    function paidCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(
            BytesUtil.doFirstParamEqualsAddress(data, msg.sender),
            "first param != sender"
        );

        if (amount > 0) {
            _addAllowanceIfNeeded(msg.sender, target, amount);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));

        return returnData;
    }
}
// File: browser/polygon/contracts_common/BaseWithStorage/ERC20/ERC20BaseToken.sol

pragma solidity 0.8.2;

contract ERC20BaseToken is SuperOperators, ERC20Events, ERC20Internal {
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    //代币供给总量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    //查询owner余额
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    //_spender可从地址_owner提款的代币数量上限
    function allowance(address owner, address spender)
    public
    view
    returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    //返回token使用的小数点后18位
    function decimals() public view returns (uint8) {
        return uint8(18);
    }

    //将数量为 amount的代币转入地址 to
    function transfer(address to, uint256 amount)
    public
    returns (bool success)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    //地址from中的amount数量的代币转入地址to（委托）
    function transferFrom(address from, address to, uint256 amount)
    public
    returns (bool success)
    {
        if (msg.sender != from && !_superOperators[msg.sender]) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != (2**256) - 1) {
                //当提币数量达到上限时，通过不减少它来节省gas (https://github.com/ethereum/EIPs/issues/717)
                //比如一个账户愿意无限制提供给另一个账户无限制转账时就不需要每次更改余额状态
                //可以无限制转账_allowances[from][msg.sender]设置成(2**256) - 1即可
                require(currentAllowance >= amount, "Not enough funds allowed");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    //burn数量为amount的代币（把创建者的token烧掉）
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    //地址owner里数量为amount的代币burn掉（用户销毁）
    function burnFor(address owner, uint256 amount) external returns (bool) {
        _burn(owner, amount);
        return true;
    }

    //设置批准地址为spender的人提币数量最大为amount
    function approve(address spender, uint256 amount)
    public
    returns (bool success)
    {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    //设置批准spender从owner提币的数量最大为amount
    function approveFor(address owner, address spender, uint256 amount)
    public
    returns (bool success)
    {
        require(
            msg.sender == owner || _superOperators[msg.sender],
            "msg.sender != owner && !superOperator"
        );
        _approveFor(owner, spender, amount);
        return true;
    }

    //增加提币额度
    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded)
    public
    returns (bool success)
    {
        require(
            msg.sender == owner || _superOperators[msg.sender],
            "msg.sender != owner && !superOperator"
        );
        _addAllowanceIfNeeded(owner, spender, amountNeeded);
        return true;
    }

    function _addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) internal virtual override
    {
        if(amountNeeded > 0 && !isSuperOperator(spender)) {
            uint256 currentAllowance = _allowances[owner][spender];
            if(currentAllowance < amountNeeded) {
                _approveFor(owner, spender, amountNeeded);
            }
        }
    }

    function _approveFor(address owner, address spender, uint256 amount) internal virtual override
    {
        require(
            owner != address(0) && spender != address(0),
            "Cannot approve with 0x0"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(to != address(0), "Cannot send to 0x0");
        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "not enough fund");
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    //铸币
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "cannot mint 0 tokens");
        uint256 currentTotalSupply = _totalSupply;
        uint256 newTotalSupply = currentTotalSupply + amount;
        require(newTotalSupply > currentTotalSupply, "overflow");
        _totalSupply = newTotalSupply;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(amount > 0, "cannot burn 0 tokens");
        if (msg.sender != from && !_superOperators[msg.sender]) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            require(
                currentAllowance >= amount,
                "Not enough funds allowed"
            );
            if (currentAllowance != (2**256) - 1) {
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }

        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "Not enough funds");
        _balances[from] = currentBalance - amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}

// File: browser/polygon/contracts_common/BaseWithStorage/ERC20/extensions/ERC20ExecuteExtension.sol

pragma solidity 0.8.2;

abstract contract ERC20ExecuteExtension is ERC20Internal{

    //_executionAdmin != _admin 所以这个权限可以被单独禁用
    address internal _executionAdmin;

    mapping(address => bool) internal _executionOperators;

    event ExecutionAdminAdminChanged(address oldAdmin, address newAdmin);

    event ExecutionOperator(address executionOperator, bool enabled);

    // 提供负责添加执行权限的地址
    function getExecutionAdmin() external view returns (address) {
        return _executionAdmin;
    }

    // 将执行管理员更改为“newAdmin”
    function changeExecutionAdmin(address newAdmin) external {
        require(msg.sender == _executionAdmin, "only executionAdmin can change executionAdmin");
        emit ExecutionAdminAdminChanged(_executionAdmin, newAdmin);
        _executionAdmin = newAdmin;
    }

    // 将executionOperator的权限更改为enabled
    function setExecutionOperator(address executionOperator, bool enabled) external {
        require(
            msg.sender == _executionAdmin,
            "only execution admin is allowed to add execution operators"
        );
        _executionOperators[executionOperator] = enabled;
        emit ExecutionOperator(executionOperator, enabled);
    }

    // 权限校验
    function isExecutionOperator(address who) public view returns (bool) {
        return _executionOperators[who];
    }

    /// @notice execute on behalf of the contract.
    /// @param to destination address fo the call.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param data the bytes sent to the destination address.
    /// @return success whether the execution was successful.
    /// @return returnData data resulting from the execution.
    function executeWithSpecificGas(address to, uint256 gasLimit, bytes calldata data) external returns (bool success, bytes memory returnData) {
        require(_executionOperators[msg.sender], "only execution operators allowed to execute on SAND behalf");
        (success, returnData) = to.call{gas: gasLimit}(data);
        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930
    }

    /// @notice approve a specific amount of token for `from` and execute on behalf of the contract.
    /// @param from address of which token will be transfered.
    /// @param to destination address fo the call.
    /// @param amount number of tokens allowed that can be transfer by the code at `to`.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param data the bytes sent to the destination address.
    /// @return success whether the execution was successful.
    /// @return returnData data resulting from the execution.
    function approveAndExecuteWithSpecificGas(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData) {
        require(_executionOperators[msg.sender], "only execution operators allowed to execute on SAND behalf");
        return _approveAndExecuteWithSpecificGas(from, to, amount, gasLimit, data);
    }

    /// @dev the reason for this function is that charging for gas here is more gas-efficient than doing it in the caller.
    /// @notice approve a specific amount of token for `from` and execute on behalf of the contract. Plus charge the gas required to perform it.
    /// @param from address of which token will be transfered.
    /// @param to destination address fo the call.
    /// @param amount number of tokens allowed that can be transfer by the code at `to`.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param tokenGasPrice price in token for the gas to be charged.
    /// @param baseGasCharge amount of gas charged on top of the gas used for the call.
    /// @param tokenReceiver recipient address of the token charged for the gas used.
    /// @param data the bytes sent to the destination address.
    /// @return success whether the execution was successful.
    /// @return returnData data resulting from the execution.
    function approveAndExecuteWithSpecificGasAndChargeForIt(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 baseGasCharge,
        address tokenReceiver,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData) {
        uint256 initialGas = gasleft();
        require(_executionOperators[msg.sender], "only execution operators allowed to execute on SAND behalf");
        (success, returnData) = _approveAndExecuteWithSpecificGas(from, to, amount, gasLimit, data);
        if (tokenGasPrice > 0) {
            _charge(from, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);
        }
    }

    /// @notice transfer 1amount1 token from `from` to `to` and charge the gas required to perform that transfer.
    /// @param from address of which token will be transfered.
    /// @param to destination address fo the call.
    /// @param amount number of tokens allowed that can be transfer by the code at `to`.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param tokenGasPrice price in token for the gas to be charged.
    /// @param baseGasCharge amount of gas charged on top of the gas used for the call.
    /// @param tokenReceiver recipient address of the token charged for the gas used.
    /// @return whether the transfer was successful.
    function transferAndChargeForGas(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 baseGasCharge,
        address tokenReceiver
    ) external returns (bool) {
        uint256 initialGas = gasleft();
        require(_executionOperators[msg.sender], "only execution operators allowed to perfrom transfer and charge");
        _transfer(from, to, amount);
        if (tokenGasPrice > 0) {
            _charge(from, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);
        }
        return true;
    }

    function _charge(
        address from,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 initialGas,
        uint256 baseGasCharge,
        address tokenReceiver
    ) internal {
        uint256 gasCharge = initialGas - gasleft();
        if(gasCharge > gasLimit) {
            gasCharge = gasLimit;
        }
        gasCharge += baseGasCharge;
        uint256 tokensToCharge = gasCharge * tokenGasPrice;
        require(tokensToCharge / gasCharge == tokenGasPrice, "overflow");
        _transfer(from, tokenReceiver, tokensToCharge);
    }

    function _approveAndExecuteWithSpecificGas(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {

        if (amount > 0) {
            _addAllowanceIfNeeded(from, to, amount);
        }
        (success, returnData) = to.call{gas: gasLimit}(data);
        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930
    }

}

// File: browser/polygon/Code/Code.sol

pragma solidity 0.8.2;

contract Code is ERC20ExecuteExtension, ERC20BasicApproveExtension, ERC20BaseToken {

    constructor(address codeAdmin, address executionAdmin, address beneficiary) public {
        _admin = codeAdmin;
        _executionAdmin = executionAdmin;
        _mint(beneficiary, 3000000000000000000000000000);
    }

    function name() public view returns (string memory) {
        return "CODE";
    }

    function symbol() public view returns (string memory) {
        return "CODE";
    }
}