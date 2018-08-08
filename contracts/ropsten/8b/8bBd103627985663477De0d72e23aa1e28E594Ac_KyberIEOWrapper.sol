pragma solidity ^0.4.23;

// File: contracts/ERC20Interface.sol

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/KyberIEOInterface.sol

interface KyberIEOInterface {
    function contribute(address contributor, uint userId, uint8 v, bytes32 r, bytes32 s) external payable returns(bool);
    function getContributorRemainingCap(uint userId) external view returns(uint capWei);
    function getIEOId() external view returns(uint);
}

// File: contracts/PermissionGroups.sol

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    constructor(address _admin) public {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// File: contracts/Withdrawable.sol

/**
 * @title Contracts that should be able to recover tokens or ethers can inherit this contract.
 * @author Ilan Doron
 * @dev Allows to recover any tokens or Ethers received in a contract.
 * Should prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {

    constructor(address _admin) PermissionGroups (_admin) public {}

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

// File: contracts/zeppelin/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/KyberIEOWrapper.sol

interface KyberNetwork {
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId) external payable returns(uint);
}


contract KyberIEOWrapper is Withdrawable {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    using SafeMath for uint;

    constructor(address _admin) public Withdrawable(_admin) {}

    function() public payable {}

    struct ContributeData {
        uint userId;
        ERC20 token;
        uint amountTwei;
        uint minConversionRate;
        uint maxDestAmountWei;
        KyberNetwork network;
        KyberIEOInterface kyberIEO;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event ContributionByToken(address contributor, uint userId, ERC20 token, uint amountSentTwei, uint tradedWei,
    uint changeTwei);

    function contributeWithToken(
        uint userId,
        ERC20 token,
        uint amountTwei,
        uint minConversionRate,
        uint maxDestAmountWei,
        KyberNetwork network,
        KyberIEOInterface kyberIEO,
        uint8 v,
        bytes32 r,
        bytes32 s) external returns(bool)
    {
        ContributeData memory data = ContributeData(
            userId,
            token,
            amountTwei,
            minConversionRate,
            maxDestAmountWei,
            network,
            kyberIEO,
            v,
            r,
            s);
        return contribute(data);
    }

    function contribute(ContributeData data) internal returns(bool) {
        uint weiCap = data.kyberIEO.getContributorRemainingCap(data.userId);
        if (data.maxDestAmountWei < weiCap) weiCap = data.maxDestAmountWei;
        require(weiCap > 0);

        uint initialTokenBalance = data.token.balanceOf(this);

        require(data.token.transferFrom(msg.sender, this, data.amountTwei));
        data.token.approve(address(data.network), data.amountTwei);

        uint weiBefore = address(this).balance;
        uint amountWei = data.network.trade(data.token, data.amountTwei, ETH_TOKEN_ADDRESS, this, weiCap,
            data.minConversionRate, this);
        uint weiAfter = address(this).balance;

        require(amountWei == weiAfter.sub(weiBefore));

        //emit event here where we still have valid "change" value
        emit ContributionByToken(
            msg.sender,
            data.userId,
            data.token,
            data.amountTwei,
            amountWei,
            (data.token.balanceOf(this).sub(initialTokenBalance))); // solium-disable-line indentation

        if (data.token.balanceOf(this) > initialTokenBalance) {
            //if not all tokens were taken by network approve value is not zereod.
            // must zero it so next time will not revert.
            data.token.approve(address(data.network), 0);
            data.token.transfer(msg.sender, (data.token.balanceOf(this).sub(initialTokenBalance)));
        }

        require(data.kyberIEO.contribute.value(amountWei)(msg.sender, data.userId, data.v, data.r, data.s));
        return true;
    }
}