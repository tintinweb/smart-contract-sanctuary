pragma solidity ^0.4.13;

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Payroll is Ownable {

    /**
     * event will be introduced in lesson 6
     */
    event AddFund(address indexed from, uint value);
    event GetPaid(address indexed employee, uint value);
    event AddEmployee(address indexed from, address indexed employee, uint salary);
    event UpdateEmployee(address indexed from, address indexed employee, uint salary);
    event RemoveEmployee(address indexed from, address indexed removed);

    using SafeMath for uint;

    /**
     * We are using mapping here, the key is already the address.
     */
    struct Employee {
        uint index;
        uint salary;
        uint lastPayday;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier shouldExist(address employeeId) {
        assert(employees[employeeId].lastPayday != 0);
        _;
    }

    modifier shouldNotExist(address employeeId) {
        assert(employees[employeeId].lastPayday == 0);
        _;
    }

    uint constant PAY_DURATION = 10 seconds;
    uint public totalSalary = 0;
    address[] employeeAddressList;

    /**
     * This contract is simple, We update employees by the key directly
     * instead of updating a copy so that we could save some gas.
     */
    mapping(address => Employee) public employees;

    function Payroll() payable public Ownable {
        owner = msg.sender;
    }

    function _partialPaid(address employeeId) private {
        uint payment = employees[employeeId].salary
        .mul(now.sub(employees[employeeId].lastPayday))
        .div(PAY_DURATION);
        employeeId.transfer(payment);
    }

    function addEmployee(address employeeId, uint salary) public onlyOwner shouldNotExist(employeeId) {
        salary = salary.mul(1 ether);

        uint index = employeeAddressList.length;
        employeeAddressList.push(employeeId);
        employees[employeeId] = Employee(index, salary, now);

        totalSalary = totalSalary.add(salary);
        AddEmployee(msg.sender, employeeId, salary);
    }

    function removeEmployee(address employeeId) public onlyOwner shouldExist(employeeId) {
        _partialPaid(employeeId);

        uint salary = employees[employeeId].salary;
        uint index = employees[employeeId].index;
        totalSalary = totalSalary.sub(salary);

        delete employees[employeeId];

        delete employeeAddressList[index];
        address moveAddress = employeeAddressList[employeeAddressList.length - 1];
        employeeAddressList[index] = moveAddress;

        // update index
        employees[moveAddress].index = index;

        // adjust length
        employeeAddressList.length -= 1;
        RemoveEmployee(msg.sender, employeeId);
    }

    function changePaymentAddress(address oldAddress, address newAddress) public onlyOwner shouldExist(oldAddress) shouldNotExist(newAddress) {
        _partialPaid(oldAddress);

        employees[newAddress] = Employee(employees[oldAddress].index, employees[oldAddress].salary, now);
        delete employees[oldAddress];
    }

    function updateEmployee(address employeeId, uint salary) public onlyOwner shouldExist(employeeId) {
        _partialPaid(employeeId);

        uint oldSalary = employees[employeeId].salary;
        salary = salary.mul(1 ether);

        employees[employeeId].salary = salary;
        employees[employeeId].lastPayday = now;
        totalSalary = totalSalary.add(salary).sub(oldSalary);

        UpdateEmployee(msg.sender, employeeId, salary);
    }

    function addFund() payable public returns (uint) {
        AddFund(msg.sender, msg.value);
        return address(this).balance;
    }

    function calculateRunway() public view returns (uint) {
        if (totalSalary == 0) {
            return 0;
        }
        return address(this).balance.div(totalSalary);
    }

    function hasEnoughFund() public view returns (bool) {
        return calculateRunway() > 0;
    }

    function getPaid() public shouldExist(msg.sender) {
        address employeeId = msg.sender;

        uint nextPayday = employees[employeeId].lastPayday.add(PAY_DURATION);
        assert(nextPayday < now);

        employees[employeeId].lastPayday = nextPayday;
        employeeId.transfer(employees[employeeId].salary);
        GetPaid(msg.sender, employees[employeeId].salary);
    }

    function getEmployerInfo() view public returns (uint balance, uint runway, uint employeeCount) {
        balance = address(this).balance;
        runway = calculateRunway();
        employeeCount = employeeAddressList.length;
    }

    function getEmployeeInfo(uint index) view public returns (address employeeAddress, uint salary, uint lastPayday, uint balance) {
        address id = employeeAddressList[index];
        employeeAddress = id;
        salary = employees[id].salary;
        lastPayday = employees[id].lastPayday;
        balance = address(id).balance;
    }

    function getEmployeeInfoById(address id) view public returns (uint salary, uint lastPayday, uint balance) {
        salary = employees[id].salary;
        lastPayday = employees[id].lastPayday;
        balance = address(id).balance;
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}