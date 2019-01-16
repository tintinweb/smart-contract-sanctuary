pragma solidity 0.4.18;

/// @title Fund Wallet - Fund raising and distribution wallet according to stake and incentive scheme.
/// @dev Not fully tested, use only in test environment.


interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract FundWallet {

    //storage
    address public admin;
    address public backupAdmin;
    uint public adminStake;
    uint public raisedBalance;
    uint public endBalance;
    bool public timePeriodsSet;
    bool public adminStaked;
    bool public endBalanceLogged;
    mapping (address => bool) public isContributor;
    mapping (address => bool) public hasClaimed;
    mapping (address => uint) public stake;
    address[] public contributors;
    //experimental time periods
    uint start;
    uint adminP;
    uint raiseP;
    uint opperateP;
    uint liquidP;
    //admin reward
    uint adminCarry; //in basis points (1% = 100bps)
    //Kyber Reserve contract address
    address reserve;
    //eth address
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    //modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBackupAdmin() {
        require(msg.sender == backupAdmin);
        _;
    }
    
    modifier timePeriodsNotSet() {
        assert(timePeriodsSet == false);
        _;
    }
    
    modifier onlyReserve() {
        require(msg.sender == reserve);
        _;
    }

    modifier onlyContributor() {
        require(isContributor[msg.sender]);
        _;
    }

    modifier adminHasStaked() {
        assert(adminStaked == true);
        _;
    }

    modifier adminHasNotStaked() {
        assert(adminStaked == false);
        _;
    }

    modifier endBalanceNotLogged() {
        assert(endBalanceLogged == false);
        _;
    }

    modifier endBalanceIsLogged() {
        assert(endBalanceLogged == true);
        _;
    }

    modifier hasNotClaimed() {
        require(!hasClaimed[msg.sender]);
        _;
    }
    
    modifier inAdminP() {
        require(now < (start + adminP));
        _;
    }

    modifier inRaiseP() {
        require(now < (start + adminP + raiseP) && now > (start + adminP));
        _;
    }

    modifier inOpperateP() {
        require(now < (start + adminP + raiseP + opperateP) && now > (start + adminP + raiseP));
        _;
    }

    modifier inLiquidP() {
        require(now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP + opperateP));
        _;
    }
    
    modifier inOpAndLiqP() {
        require(now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP));
        _;
    }

    modifier inClaimP() {
        require(now > (start + adminP + raiseP + opperateP + liquidP));
        _;
    }

    //events
    event ContributorAdded(address _contributor);
    event ContributorRemoval(address _contributor);
    event ContributorDeposit(address sender, uint value);
    event ContributorDepositReturn(address _contributor, uint value);
    event AdminDeposit(address sender, uint value);
    event AdminDepositReturned(address sender, uint value);
    event TokenPulled(ERC20 token, uint amount, address sendTo);
    event EtherPulled(uint amount, address sendTo);
    event TokenWithdraw(ERC20 token, uint amount, address sendTo);
    event EtherWithdraw(uint amount, address sendTo);


    /// @notice Constructor, initialises admin wallets.
    /// @param _admin Is main opperator address.
    /// @param _backupAdmin Is an address which can change the admin address - recommend cold wallet.
    function FundWallet(address _admin, address _backupAdmin) public {
        require(_admin != address(0));
        admin = _admin;
        backupAdmin = _backupAdmin;
    }
    
    /// @notice function to set the stake and incentive scheme for the admin;
    /// @param _adminStake Is the amount that the admin will contribute to the fund.
    /// @param _adminCarry The admins performance fee in profitable scenario, measured in basis points (1% = 100bps).
    function setFundScheme(uint _adminStake, uint _adminCarry) public onlyAdmin inAdminP {
        require(_adminStake > 0);
        adminStake = _adminStake;
        adminCarry = _adminCarry; //bps
    }
    
    /// @notice function to set time periods.
    /// @param _adminP The amount of time during which the admin can set fund parameters and add contributors.
    /// @param _raiseP The amount of time during which contributors and admin can contribute to the fund. In minutes for testing.
    /// @param _opperateP The amount of time during which the fund is actively trading/investing. In minutes for testing.
    /// @param _liquidP The amount of time the admin has to liquidate the fund into base currency - Ether. In minutes for testing.
    function setTimePeriods(uint _adminP, uint _raiseP, uint _opperateP, uint _liquidP) public timePeriodsNotSet {
        start = now;
        adminP = _adminP * (60 seconds);
        raiseP = _raiseP * (60 seconds);
        opperateP = _opperateP * (60 seconds);
        liquidP = _liquidP * (60 seconds);
        timePeriodsSet = true;
    }
    
    /// @dev set or change reserve address
    /// @param _reserve the address of corresponding kyber reserve.
    function setReserve (address _reserve) public onlyAdmin inAdminP {
        reserve = _reserve;
    }

    /// @notice Fallback function - recieves ETH but doesn&#39;t alter contributor stakes or raised balance.
    function() public payable {
    }

    /// @notice Function to change the admins address
    /// @dev Only available to the back up admin.
    /// @param _newAdmin address of the new admin.
    function changeAdmin(address _newAdmin) public onlyBackupAdmin {
        admin = _newAdmin;
    }

    /// @notice Function to add contributor address.
    /// @dev Only available to admin and in the raising period.
    /// @param _contributor Address of the new contributor.
    function addContributor(address _contributor) public onlyAdmin inAdminP {
        require(!isContributor[ _contributor]); //only new contributor
        require(_contributor != admin);
        isContributor[ _contributor] = true;
        contributors.push( _contributor);
        ContributorAdded( _contributor);
    }

    /// @notice Function to remove contributor address.
    /// @dev Only available to admin and in the raising period. Returns balance of contributor if they have deposited.
    /// @param _contributor Address of the contributor to be removed.
    function removeContributor(address _contributor) public onlyAdmin inAdminP {
        require(isContributor[_contributor]);
        isContributor[_contributor] = false;
        for (uint i=0; i < contributors.length - 1; i++)
            if (contributors[i] == _contributor) {
                contributors[i] = contributors[contributors.length - 1];
                break;
            }
        contributors.length -= 1;
        ContributorRemoval(_contributor);
    }
    
    /// @notice Function to get contributor addresses.
    function getContributors() public constant returns (address[]){
        return contributors;
    }
    
    /// @notice Function for contributor to deposit funds.
    /// @dev Only available to contributors after admin had deposited their stake, and in the raising period.
    function contributorDeposit() public onlyContributor adminHasStaked inRaiseP payable {
        if (adminStake >= msg.value && msg.value > 0 && stake[msg.sender] < adminStake) {
            raisedBalance += msg.value;
            stake[msg.sender] += msg.value;
            ContributorDeposit(msg.sender, msg.value);
        }
        else {
            revert();
        }
    }
    
    /// @notice Function for contributor to reclaim their deposit.
    /// @dev Only available to contributor in the raising period. Removes contributor on refund.
    function contributorRefund() public onlyContributor inRaiseP {
        isContributor[msg.sender] = false;
        for (uint i=0; i < contributors.length - 1; i++)
            if (contributors[i] == msg.sender) {
                contributors[i] = contributors[contributors.length - 1];
                break;
            }
        contributors.length -= 1;
        ContributorRemoval(msg.sender);

        if (stake[msg.sender] > 0) {
            msg.sender.transfer(stake[msg.sender]);
            raisedBalance -= stake[msg.sender];
            delete stake[msg.sender];
            ContributorDepositReturn(msg.sender, stake[msg.sender]);
        }
    }

    /// @notice Function for admin to deposit their stake.
    /// @dev Only available to admin and in the raising period.
    function adminDeposit() public onlyAdmin adminHasNotStaked inRaiseP payable {
        if (msg.value == adminStake) {
            raisedBalance += msg.value;
            stake[msg.sender] += msg.value;
            adminStaked = true;
            AdminDeposit(msg.sender, msg.value);
        }
        else {
            revert();
        }
    }
    
    /// @notice Funtion for admin to reclaim their contribution/stake.
    /// @dev Only available to admin and in the raising period and if admin is the only one who has contributed to the fund.
    function adminRefund() public onlyAdmin adminHasStaked inRaiseP {
        require(raisedBalance == adminStake);
        admin.transfer(adminStake);
        adminStaked = false;
        raisedBalance -= adminStake;
        AdminDepositReturned(msg.sender, adminStake);
    }
    
    /// @notice Funtion for admin to withdraw ERC20 token while fund is opperating.
    /// @dev Only available to admin and in the opperating period
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin inOpperateP {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }
    
    /// @notice Funtion for admin to withdraw ERC20 token while fund is opperating.
    /// @dev Only available to admin and in the opperating period
    function withdrawEther(uint amount, address sendTo) external onlyAdmin inOpperateP {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }

    /// @notice Funtion to log the ending balance after liquidation period. Used as point of reference to calculate profit/loss.
    /// @dev Only available in claim period and only available once.
    function logEndBal() public inClaimP endBalanceNotLogged {
        endBalance = address(this).balance;
        endBalanceLogged = true;
    }

    /// @notice Funtion for admin to calim their payout.
    /// @dev Only available to admin in claim period and once the ending balance has been logged. Payout depends on profit or loss.
    function adminClaim() public onlyAdmin inClaimP endBalanceIsLogged hasNotClaimed {
        if (endBalance > raisedBalance) {
            admin.transfer(((endBalance - raisedBalance)*(adminCarry))/10000); //have variable for adminReward
            admin.transfer(((((endBalance - raisedBalance)*(10000-adminCarry))/10000)*adminStake)/raisedBalance); // profit share
            admin.transfer(adminStake); //initial stake
            hasClaimed[msg.sender] = true;
        }
        else {
            admin.transfer((endBalance*adminStake)/raisedBalance);
            hasClaimed[msg.sender] = true;
        }
    }

    /// @notice Funtion for contributor to claim their payout.
    /// @dev Only available to contributor in claim period and once the ending balance has been logged. Payout depends on profit or loss.
    function contributorClaim() public onlyContributor inClaimP endBalanceIsLogged hasNotClaimed {
        if (endBalance > raisedBalance) {
            msg.sender.transfer(((((endBalance - raisedBalance)*(10000-adminCarry))/10000)*stake[msg.sender])/raisedBalance); // profit share
            msg.sender.transfer(stake[msg.sender]); //initial stake
            hasClaimed[msg.sender] = true;
        }
        else {
            msg.sender.transfer((endBalance*stake[msg.sender])/raisedBalance);
            hasClaimed[msg.sender] = true;
        }
    }
    
    //functions to allow trading with reserve address

    /// @dev send erc20token to the destination address
    /// @param token ERC20 The address of the token contract
    function pullToken(ERC20 token, uint amount, address sendTo) external {
        require(msg.sender == reserve);
        require(now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP));
        require(token.transfer(sendTo, amount));
        TokenPulled(token, amount, sendTo);
    }

    ///@dev Send ether to the destination address
    function pullEther(uint amount, address sendTo) external {
        require(msg.sender == reserve);
        require(now < (start + adminP + raiseP + opperateP) && now > (start + adminP + raiseP));
        sendTo.transfer(amount);
        EtherPulled(amount, sendTo);
    }
    
    ///@dev function to check balance only returns balances in opperating and liquidating periods
    function checkBalance(ERC20 token) public view returns (uint) {
        if (now < (start + adminP + raiseP + opperateP) && now > (start + adminP + raiseP)) {
            if (token == ETH_TOKEN_ADDRESS) {
                return this.balance;
            }
            else {
                return token.balanceOf(this);
            }
        }
        if (now < (start + adminP + raiseP + opperateP + liquidP) && now > (start + adminP + raiseP + opperateP)) {
            if (token == ETH_TOKEN_ADDRESS) {
                return 0;
            }
            else {
                return token.balanceOf(this);
            }
        }
        else return 0;
    }

}