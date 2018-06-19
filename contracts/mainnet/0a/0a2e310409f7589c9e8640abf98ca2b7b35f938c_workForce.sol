pragma solidity ^0.4.11;

contract ERC20 
{
    function totalSupply() constant returns (uint);
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract workForce
{
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEmployee()
    {
        require(workcrew[ employeeAddressIndex[msg.sender] ].yearlySalaryUSD > 0);
         _;
    }

    /* Oracle address and owner address are the same */
    modifier onlyOracle()
    {
        require(msg.sender == owner);
        _;
    }

    struct Employee
    {
        uint employeeId;
        string employeeName;
        address employeeAddress;
        uint[3] usdEthAntTokenDistribution;
        uint yearlySalaryUSD;
        uint startDate;
        uint lastPayday;
        uint lastTokenConfigDay;
    }

    
    /* Using a dynamic array because can&#39;t iterate mappings, or use push,length,delete cmds? */
    Employee[] workcrew;
    uint employeeIndex;
    mapping( uint => uint ) employeeIdIndex;
    mapping( string => uint ) employeeNameIndex;
    mapping( address => uint ) employeeAddressIndex;
    
    mapping( address => uint ) public exchangeRates;
    address owner;
    uint creationDate;

    /* ANT token is Catnip */
    address antAddr = 0x529ae9b61c174a3e005eda67eb755342558a1c3f;
    /* USD token is Space Dollars */
    address usdAddr = 0x41f1dcb0d41bf1e143461faf42c577a9219da415;

    ERC20 antToken = ERC20(antAddr);
    ERC20 usdToken = ERC20(usdAddr);
    /* set to 1 Ether equals 275.00 USD */
    uint oneUsdToEtherRate;


    /* Constructor sets 1USD to equal 3.2 Finney or 2 Catnip */
    function workForce() public
    {
        owner = msg.sender;
        creationDate = now;
        employeeIndex = 1000;

        exchangeRates[antAddr] = 2;
        oneUsdToEtherRate = 3200000000000000;
    }

    function indexTheWorkcrew() private
    {
        for( uint x = 0; x < workcrew.length; x++ )
        {
            employeeIdIndex[ workcrew[x].employeeId ] = x;
            employeeNameIndex[ workcrew[x].employeeName ] = x;
            employeeAddressIndex[ workcrew[x].employeeAddress ] = x;
        }
    }

    function incompletePercent(uint[3] _distribution) internal returns (bool)
    {
        uint sum;
        for( uint x = 0; x < 3; x++ ){ sum += _distribution[x]; }
        if( sum != 100 ){ return true; }
        else{ return false; }
    }

    function addEmployee(address _employeeAddress, string _employeeName, uint[3] _tokenDistribution, uint _initialUSDYearlySalary) onlyOwner
    {
        if( incompletePercent( _tokenDistribution)){ revert; }
        employeeIndex++;
        Employee memory newEmployee;
        newEmployee.employeeId = employeeIndex;
        newEmployee.employeeName = _employeeName;
        newEmployee.employeeAddress = _employeeAddress;
        newEmployee.usdEthAntTokenDistribution = _tokenDistribution;
        newEmployee.yearlySalaryUSD = _initialUSDYearlySalary;
        newEmployee.startDate = now;
        newEmployee.lastPayday = now;
        newEmployee.lastTokenConfigDay = now;
        workcrew.push(newEmployee);
        indexTheWorkcrew();
    }

    function setEmployeeSalary(uint _employeeID, uint _yearlyUSDSalary) onlyOwner
    {
        workcrew[ employeeIdIndex[_employeeID] ].yearlySalaryUSD = _yearlyUSDSalary;
    }

    function removeEmployee(uint _employeeID) onlyOwner
    {
        delete workcrew[ employeeIdIndex[_employeeID] ];
        indexTheWorkcrew();
    }

    function addFunds() payable onlyOwner returns (uint) 
    {
        return this.balance;
    }

    function getTokenBalance() constant returns (uint, uint)
    {
        return ( usdToken.balanceOf(address(this)), antToken.balanceOf(address(this)) );
    }

    function scapeHatch() onlyOwner
    {
        selfdestructTokens();
        delete workcrew;
        selfdestruct(owner);
    }

    function selfdestructTokens() private
    {
        antToken.transfer( owner,(antToken.balanceOf(address(this))));
        usdToken.transfer( owner, (usdToken.balanceOf(address(this))));
    }

    function getEmployeeCount() constant onlyOwner returns (uint)
    {
        return workcrew.length;
    }

    function getEmployeeInfoById(uint _employeeId) constant onlyOwner returns (uint, string, uint, address, uint)
    {
        uint x = employeeIdIndex[_employeeId];
        return (workcrew[x].employeeId, workcrew[x].employeeName, workcrew[x].startDate,
                workcrew[x].employeeAddress, workcrew[x].yearlySalaryUSD );
    }
    
    function getEmployeeInfoByName(string _employeeName) constant onlyOwner returns (uint, string, uint, address, uint)
    {
        uint x = employeeNameIndex[_employeeName];
        return (workcrew[x].employeeId, workcrew[x].employeeName, workcrew[x].startDate,
                workcrew[x].employeeAddress, workcrew[x].yearlySalaryUSD );
    }

    function calculatePayrollBurnrate() constant onlyOwner returns (uint)
    {
        uint monthlyPayout;
        for( uint x = 0; x < workcrew.length; x++ )
        {
            monthlyPayout += workcrew[x].yearlySalaryUSD / 12;
        }
        return monthlyPayout;
    }

    function calculatePayrollRunway() constant onlyOwner returns (uint)
    {
        uint dailyPayout = calculatePayrollBurnrate() / 30;
        
        uint UsdBalance = usdToken.balanceOf(address(this));
        UsdBalance += this.balance / oneUsdToEtherRate;
        UsdBalance += antToken.balanceOf(address(this)) / exchangeRates[antAddr];
        
        uint daysRemaining = UsdBalance / dailyPayout;
        return daysRemaining;
    }

    function setPercentTokenAllocation(uint _usdTokens, uint _ethTokens, uint _antTokens) onlyEmployee
    {
        if( _usdTokens + _ethTokens + _antTokens != 100 ){revert;}
        
        uint x = employeeAddressIndex[msg.sender];

        /* change from 1 hours to 24 weeks */
        if( now < workcrew[x].lastTokenConfigDay + 1 hours ){revert;}
        workcrew[x].lastTokenConfigDay = now;
        workcrew[x].usdEthAntTokenDistribution[0] = _usdTokens;
        workcrew[x].usdEthAntTokenDistribution[1] = _ethTokens;
        workcrew[x].usdEthAntTokenDistribution[2] = _antTokens;
    }

    function payday(uint _employeeId) public onlyEmployee
    {
        uint x = employeeIdIndex[_employeeId];

        /* Change to 4 weeks for monthly pay period */
        if( now < workcrew[x].lastPayday + 5 minutes ){ revert; }
        if( msg.sender != workcrew[x].employeeAddress ){ revert; }
        workcrew[x].lastPayday = now;

        /* 7680 is for 5min pay periods. Change to 12 for monthly pay period */
        uint paycheck = workcrew[x].yearlySalaryUSD / 7680;
        uint usdTransferAmount = paycheck * workcrew[x].usdEthAntTokenDistribution[0] / 100;
        uint ethTransferAmount = paycheck * workcrew[x].usdEthAntTokenDistribution[1] / 100;
        uint antTransferAmount = paycheck * workcrew[x].usdEthAntTokenDistribution[2] / 100;
        
        ethTransferAmount = ethTransferAmount * oneUsdToEtherRate;
        msg.sender.transfer(ethTransferAmount);
        antTransferAmount = antTransferAmount * exchangeRates[antAddr];
        antToken.transfer( workcrew[x].employeeAddress, antTransferAmount );
        usdToken.transfer( workcrew[x].employeeAddress, usdTransferAmount );
    }
    
    /* setting 1 USD equals X amount of tokens */
    function setTokenExchangeRate(address _token, uint _tokenValue) onlyOracle
    {
        exchangeRates[_token] = _tokenValue;
    }

    /* setting 1 USD equals X amount of wei */
    function setUsdToEtherExchangeRate(uint _weiValue) onlyOracle
    {
        oneUsdToEtherRate = _weiValue;
    }

    function UsdToEtherConvert(uint _UsdAmount) constant returns (uint)
    {
        uint etherVal = _UsdAmount * oneUsdToEtherRate;
        return etherVal;
    }

    function UsdToTokenConvert(address _token, uint _UsdAmount) constant returns (uint)
    {
        uint tokenAmount = _UsdAmount * exchangeRates[_token];
        return tokenAmount;
    }
}