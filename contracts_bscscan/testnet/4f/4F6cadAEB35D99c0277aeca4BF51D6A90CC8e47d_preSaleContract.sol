pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function decimals() external view returns (uint8);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract preSaleContract {
    using SafeMath for uint256;
    using Address for address;

    IBEP20 public token;
    address payable public owner;
    uint256 constant public percentDivider = 100;
    uint256 public tokenPerBnb;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldtoken;
    uint256 public amountRaised;
    uint256 public totalSupply;
    uint256[4] public refPercent = [20, 23, 30, 30];
    uint256[3] public refLimit = [10 ether, 20 ether, 30 ether];
    struct PreSale{
        uint256 Supply;
        uint256 ValidationPeriodStart;
        uint256 ValidationPeriodEnd;
        uint256 Sold;
        uint256 Remaining;
        uint256 initialPercent;
        uint256 vestingPercent;
        uint256 ClifDuration;
        uint256 VestingPeriod;
    }
    struct Buyer {
        uint256 Amount;
        uint256 Claimed;
        uint256 Remaining;
        uint256 tokenPerDay;
        uint256 LastClaimTime;
    }
    PreSale public privatePreSale;
    PreSale public preSaleI;
    PreSale public preSaleII;   

    bool public isPublicSaleEnable;
    bool public isPrivateSaleEnable;
    bool public isTeamSaleEnable;

    struct refData {
        uint256 refBalance;
        uint256 refcount;
        uint256 refEarning;
    }

    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public coinBalance;
    mapping(address => refData) public refDataStore;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public teamlist;
    mapping(address => uint256) public nextClaimTime;
    mapping(address => Buyer) public ClientsI;
    mapping(address => Buyer) public ClientsII;
    mapping(address => Buyer) public PrivateClients;

    modifier onlyOwner() {
        require(msg.sender == owner, "PreSale: Not an owner");
        _;
    }

    modifier isTeamMember(address _user) {
        require(teamlist[_user], "PreSale: Not a team member");
        _;
    }

    modifier isWhitelisted(address _user) {
        require(whitelist[_user], "PreSale: Not a whitelist user");
        _;
    }

    modifier isContract(address _user) {
        require(!address(_user).isContract(), "PreSale: contract can not buy");
        _;
    }

    event Buytoken(address _user, uint256 _amount);
    event PRIVATEPRESALEBUY(address user, uint256 amount,uint256 time);
    event PRESALEIBUY(address user, uint256 amount,uint256 time);
    event PRESALEIIBUY(address user, uint256 amount,uint256 time);
    event PRIVATEPRESALECLAIMED(address user, uint256 amount,uint256 time);
    event PRESALEICLAIMED(address user, uint256 amount,uint256 time);
    event PRESALEIICLAIMED(address user, uint256 amount,uint256 time);
    event STAKED(address user, uint256 amount,uint256 time);
    event STAKECLAIMED(address user, uint256 amount,uint256 time);
    event STAKEUNSTAKED(address user, uint256 amount,uint256 time);
    event AdvisoryCLAIMED(address user, uint256 amount,uint256 time);

    constructor() {
        owner = payable(msg.sender);
        token = IBEP20(0xB0b0A907E29D5bDb04ffb20dD84A49E8b721e93c);
        totalSupply = 8000000000 * 1e18;
        tokenPerBnb = 100000;
        minAmount = 0.01 ether;
        maxAmount = 10 ether;
        preSaleStartTime = block.timestamp;
        isPublicSaleEnable = true;
        isPrivateSaleEnable = true;
        isTeamSaleEnable = true;

        privatePreSale.Supply = totalSupply;
        privatePreSale.Remaining = privatePreSale.Supply;
        privatePreSale.ValidationPeriodStart = preSaleStartTime;
        privatePreSale.ValidationPeriodEnd = preSaleStartTime + 10 minutes;
        privatePreSale.initialPercent = 25;
        privatePreSale.vestingPercent = 75;
        privatePreSale.ClifDuration = 10 minutes;
        privatePreSale.VestingPeriod = 290 minutes;

        preSaleI.Supply = totalSupply;
        preSaleI.Remaining = preSaleI.Supply;
        preSaleI.ValidationPeriodStart = preSaleStartTime + 10 minutes;
        preSaleI.ValidationPeriodEnd = preSaleStartTime + 24 minutes;
        preSaleI.initialPercent = 25;
        preSaleI.vestingPercent = 75;
        preSaleI.ClifDuration = 10 minutes;
        preSaleI.VestingPeriod = 290 minutes;

        preSaleII.Supply = totalSupply;
        preSaleII.Remaining = preSaleII.Supply;
        preSaleII.ValidationPeriodStart = preSaleStartTime + 24 minutes;
        preSaleII.ValidationPeriodEnd = preSaleStartTime + 38 minutes;
        preSaleII.initialPercent = 25;
        preSaleII.vestingPercent = 75;
        preSaleII.ClifDuration = 10 minutes;
        preSaleII.VestingPeriod = 290 minutes;

        preSaleEndTime = preSaleStartTime + 38 minutes;
    }

    receive() external payable {}

    function buyPrivateSale(address payable _referrer) public payable isContract(msg.sender)  isTeamMember(msg.sender){
        require(isPublicSaleEnable,"PreSale: Sale disbaled");
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PreSale: invalid referrer"
        );
        require(msg.value >= minAmount, "PreSale: Amount less than minimum");
        require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "PreSale: Amount exceeded max buy limit"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );
        uint256 numberOftokens = bnbTotoken(msg.value);
        require(msg.value >= minAmount && msg.value <= maxAmount,"PRESALE:: Invalid Amount");
        require(block.timestamp > privatePreSale.ValidationPeriodStart, "PRESALE:: Not Started Yet");
        require(block.timestamp < privatePreSale.ValidationPeriodEnd, "PRESALE:: Ended");
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOftokens);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);
        soldtoken = soldtoken.add(numberOftokens);
        amountRaised = amountRaised.add(msg.value);
        refDataStore[_referrer].refBalance = refDataStore[_referrer]
            .refBalance
            .add(msg.value);
        refDataStore[_referrer].refcount++;
        privatePreSale.Remaining = privatePreSale.Remaining.sub(numberOftokens);
        privatePreSale.Sold = privatePreSale.Sold.add(numberOftokens);
        PrivateClients[msg.sender].tokenPerDay = PrivateClients[msg.sender].tokenPerDay.add(CalculatePerDay(numberOftokens,privatePreSale.VestingPeriod));
        PrivateClients[msg.sender].Amount = PrivateClients[msg.sender].Amount.add(numberOftokens);
        PrivateClients[msg.sender].Remaining = PrivateClients[msg.sender].Remaining.add(numberOftokens);
        PrivateClients[msg.sender].LastClaimTime = preSaleEndTime;
        uint256 refAmount = 0;
        if (_referrer != address(0)) {
            if (
                refDataStore[_referrer].refBalance > 0 ether &&
                refDataStore[_referrer].refBalance <= refLimit[0]
            ) {
                refAmount = msg.value.mul(refPercent[0]).div(percentDivider);
            } else if (
                refDataStore[_referrer].refBalance > refLimit[0] &&
                refDataStore[_referrer].refBalance <= refLimit[1]
            ) {
                refAmount = msg.value.mul(refPercent[1]).div(percentDivider);
            } else if (
                refDataStore[_referrer].refBalance > refLimit[1] &&
                refDataStore[_referrer].refBalance <= refLimit[2]
            ) {
                refAmount = msg.value.mul(refPercent[2]).div(percentDivider);
            } else {
                refAmount = msg.value.mul(refPercent[3]).div(percentDivider);
            }
            _referrer.transfer(refAmount);
        }
        owner.transfer(msg.value.sub(refAmount));
        refDataStore[_referrer].refEarning = refDataStore[_referrer]
            .refEarning
            .add(refAmount);
        emit PRIVATEPRESALEBUY(msg.sender, numberOftokens.div(10**(token.decimals())), block.timestamp);
    }
    function buypreSaleI(address payable _referrer) public payable isContract(msg.sender) isWhitelisted(msg.sender){
        require(isPublicSaleEnable,"PreSale: Sale disbaled");
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PreSale: invalid referrer"
        );
        require(msg.value >= minAmount, "PreSale: Amount less than minimum");
        require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "PreSale: Amount exceeded max buy limit"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );
        uint256 numberOftokens = bnbTotoken(msg.value);
        require(msg.value >= minAmount && msg.value <= maxAmount,"PRESALE:: Invalid Amount");
        require(block.timestamp > preSaleI.ValidationPeriodStart, "PRESALE:: Not Started Yet");
        require(block.timestamp < preSaleI.ValidationPeriodEnd, "PRESALE:: Ended");
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOftokens);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);
        soldtoken = soldtoken.add(numberOftokens);
        amountRaised = amountRaised.add(msg.value);
        refDataStore[_referrer].refBalance = refDataStore[_referrer]
            .refBalance
            .add(msg.value);
        refDataStore[_referrer].refcount++;
        preSaleI.Remaining = preSaleI.Remaining.sub(numberOftokens);
        preSaleI.Sold = preSaleI.Sold.add(numberOftokens);
        ClientsI[msg.sender].tokenPerDay = ClientsI[msg.sender].tokenPerDay.add(CalculatePerDay(numberOftokens,preSaleI.VestingPeriod));
        ClientsI[msg.sender].Amount = ClientsI[msg.sender].Amount.add(numberOftokens);
        ClientsI[msg.sender].Remaining = ClientsI[msg.sender].Remaining.add(numberOftokens);
        ClientsI[msg.sender].LastClaimTime = preSaleEndTime;
        uint256 refAmount = 0;
        if (_referrer != address(0)) {
            if (
                refDataStore[_referrer].refBalance > 0 ether &&
                refDataStore[_referrer].refBalance <= refLimit[0]
            ) {
                refAmount = msg.value.mul(refPercent[0]).div(percentDivider);
            } else if (
                refDataStore[_referrer].refBalance > refLimit[0] &&
                refDataStore[_referrer].refBalance <= refLimit[1]
            ) {
                refAmount = msg.value.mul(refPercent[1]).div(percentDivider);
            } else if (
                refDataStore[_referrer].refBalance > refLimit[1] &&
                refDataStore[_referrer].refBalance <= refLimit[2]
            ) {
                refAmount = msg.value.mul(refPercent[2]).div(percentDivider);
            } else {
                refAmount = msg.value.mul(refPercent[3]).div(percentDivider);
            }
            _referrer.transfer(refAmount);
        }
        owner.transfer(msg.value.sub(refAmount));
        refDataStore[_referrer].refEarning = refDataStore[_referrer]
            .refEarning
            .add(refAmount);
        emit PRESALEIBUY(msg.sender, numberOftokens.div(10**(token.decimals())), block.timestamp);
    }
    function buypreSaleII(address payable _referrer) public payable isContract(msg.sender)  {
        require(isPublicSaleEnable,"PreSale: Sale disbaled");
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PreSale: invalid referrer"
        );
        require(msg.value >= minAmount, "PreSale: Amount less than minimum");
        require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "PreSale: Amount exceeded max buy limit"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );
        uint256 numberOftokens = bnbTotoken(msg.value);
        require(msg.value >= minAmount && msg.value <= maxAmount,"PRESALE:: Invalid Amount");
        require(block.timestamp > preSaleII.ValidationPeriodStart, "PRESALE:: Not Started Yet");
        require(block.timestamp < preSaleII.ValidationPeriodEnd, "PRESALE:: Ended");
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOftokens);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);
        soldtoken = soldtoken.add(numberOftokens);
        amountRaised = amountRaised.add(msg.value);
        refDataStore[_referrer].refBalance = refDataStore[_referrer]
            .refBalance
            .add(msg.value);
        refDataStore[_referrer].refcount++;
        preSaleII.Remaining = preSaleII.Remaining.sub(numberOftokens);
        preSaleII.Sold = preSaleII.Sold.add(numberOftokens);
        ClientsII[msg.sender].tokenPerDay = ClientsII[msg.sender].tokenPerDay.add(CalculatePerDay(numberOftokens,preSaleII.VestingPeriod));
        ClientsII[msg.sender].Amount = ClientsII[msg.sender].Amount.add(numberOftokens);
        ClientsII[msg.sender].Remaining = ClientsII[msg.sender].Remaining.add(numberOftokens);
        ClientsII[msg.sender].LastClaimTime = preSaleEndTime;
        uint256 refAmount = 0;
        if (_referrer != address(0)) {
            if (
                refDataStore[_referrer].refBalance > 0 ether &&
                refDataStore[_referrer].refBalance <= refLimit[0]
            ) {
                refAmount = msg.value.mul(refPercent[0]).div(percentDivider);
            } else if (
                refDataStore[_referrer].refBalance > refLimit[0] &&
                refDataStore[_referrer].refBalance <= refLimit[1]
            ) {
                refAmount = msg.value.mul(refPercent[1]).div(percentDivider);
            } else if (
                refDataStore[_referrer].refBalance > refLimit[1] &&
                refDataStore[_referrer].refBalance <= refLimit[2]
            ) {
                refAmount = msg.value.mul(refPercent[2]).div(percentDivider);
            } else {
                refAmount = msg.value.mul(refPercent[3]).div(percentDivider);
            }
            _referrer.transfer(refAmount);
        }
        owner.transfer(msg.value.sub(refAmount));
        refDataStore[_referrer].refEarning = refDataStore[_referrer]
            .refEarning
            .add(refAmount);
        emit PRESALEIIBUY(msg.sender, numberOftokens.div(10**(token.decimals())), block.timestamp);
    }
    function claimPrivateSale() public isContract(msg.sender)  isTeamMember(msg.sender) {
        require(block.timestamp >= preSaleEndTime, "PreSale:: Not Ended Yet");
        require(PrivateClients[msg.sender].Claimed < PrivateClients[msg.sender].Amount,"PreSale:: Claimed All The tokens");
        if(PrivateClients[msg.sender].Claimed == 0){
            PrivateClients[msg.sender].Claimed = PrivateClients[msg.sender].Claimed.add(PrivateClients[msg.sender].Amount.mul(privatePreSale.initialPercent).div(percentDivider));
            token.transfer(msg.sender, PrivateClients[msg.sender].Claimed);
            PrivateClients[msg.sender].LastClaimTime = preSaleEndTime.add(privatePreSale.ClifDuration);
            emit PRIVATEPRESALECLAIMED(msg.sender, PrivateClients[msg.sender].Claimed.div(10**(token.decimals())), block.timestamp);
        }
        else{
            require(block.timestamp > PrivateClients[msg.sender].LastClaimTime);
            uint256 claimable = PrivateClients[msg.sender].tokenPerDay.mul((block.timestamp.sub(PrivateClients[msg.sender].LastClaimTime)).div(1 minutes));
            PrivateClients[msg.sender].Claimed = PrivateClients[msg.sender].Claimed.add(claimable);
            token.transfer(msg.sender, claimable);
            PrivateClients[msg.sender].LastClaimTime = block.timestamp;
            emit PRIVATEPRESALECLAIMED(msg.sender, PrivateClients[msg.sender].Claimed.div(10**(token.decimals())), block.timestamp); 
        }
    }
    function claimpreSaleI() public isContract(msg.sender)  isWhitelisted(msg.sender) {
        require(block.timestamp >= preSaleEndTime, "PreSale:: Not Ended Yet");
        require(ClientsI[msg.sender].Claimed < ClientsI[msg.sender].Amount,"PreSale:: Claimed All The tokens");
        if(ClientsI[msg.sender].Claimed == 0){
            ClientsI[msg.sender].Claimed = ClientsI[msg.sender].Claimed.add(ClientsI[msg.sender].Amount.mul(preSaleI.initialPercent).div(percentDivider));
            token.transfer(msg.sender, ClientsI[msg.sender].Claimed);
            ClientsI[msg.sender].LastClaimTime = preSaleEndTime.add(preSaleI.ClifDuration);
            emit PRESALEICLAIMED(msg.sender, ClientsI[msg.sender].Claimed.div(10**(token.decimals())), block.timestamp);
        }
        else{
            require(block.timestamp > ClientsI[msg.sender].LastClaimTime);
            uint256 claimable = ClientsI[msg.sender].tokenPerDay.mul((block.timestamp.sub(ClientsI[msg.sender].LastClaimTime)).div(1 minutes));
            ClientsI[msg.sender].Claimed = ClientsI[msg.sender].Claimed.add(claimable);
            token.transfer(msg.sender, claimable);
            ClientsI[msg.sender].LastClaimTime = block.timestamp;
            emit PRESALEICLAIMED(msg.sender, ClientsI[msg.sender].Claimed.div(10**(token.decimals())), block.timestamp); 
        }
    }
    function claimpreSaleII() public isContract(msg.sender) {
        require(block.timestamp >= preSaleEndTime, "PreSale:: Not Ended Yet");
        require(ClientsII[msg.sender].Claimed < ClientsII[msg.sender].Amount,"PreSale:: Claimed All The tokens");
        if(ClientsII[msg.sender].Claimed == 0){
            ClientsII[msg.sender].Claimed = ClientsII[msg.sender].Claimed.add(ClientsII[msg.sender].Amount.mul(preSaleII.initialPercent).div(percentDivider));
            token.transfer(msg.sender, ClientsII[msg.sender].Claimed);
            ClientsII[msg.sender].LastClaimTime = preSaleEndTime.add(preSaleII.ClifDuration);
            emit PRESALEIICLAIMED(msg.sender, ClientsII[msg.sender].Claimed.div(10**(token.decimals())), block.timestamp);
        }
        else{
            require(block.timestamp > ClientsII[msg.sender].LastClaimTime);
            uint256 claimable = ClientsII[msg.sender].tokenPerDay.mul((block.timestamp.sub(ClientsII[msg.sender].LastClaimTime)).div(1 minutes));
            ClientsII[msg.sender].Claimed = ClientsII[msg.sender].Claimed.add(claimable);
            token.transfer(msg.sender, claimable);
            ClientsII[msg.sender].LastClaimTime = block.timestamp;
            emit PRESALEIICLAIMED(msg.sender, ClientsII[msg.sender].Claimed.div(10**(token.decimals())), block.timestamp); 
        }
    }

    function CalculatePerDay(uint256 amount,uint256 _VestingPeriod) internal pure returns (uint256) {
        return amount.mul(1 minutes).div(_VestingPeriod);
    }

    function bnbTotoken(uint256 _amount) public view returns (uint256) {
        uint256 numberOftokens = _amount.mul(tokenPerBnb);
        return numberOftokens;
    }

    function getProgress() public view returns (uint256 _percent) {
        uint256 remaining = totalSupply.sub(soldtoken);
        remaining = remaining.mul(percentDivider).div(totalSupply);
        uint256 hundred = percentDivider;
        return hundred.sub(remaining);
    }

    // to change Price of the token
    function changePrice(uint256 _tokenPerBnb) external onlyOwner {
        tokenPerBnb = _tokenPerBnb;
    }

    function setAmountLimits(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _total
    ) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        totalSupply = _total;
    }

    function setPublicPreSale(bool _value, uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        isPublicSaleEnable = _value;
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function setPrivatePreSale(bool _value, uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        isPrivateSaleEnable = _value;
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function setTeamPreSale(bool _value, uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        isTeamSaleEnable = _value;
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function setRefPercent(
        uint256 _percent1,
        uint256 _percent2,
        uint256 _percent3,
        uint256 _percent4
    ) external onlyOwner {
        refPercent[0] = _percent1;
        refPercent[1] = _percent2;
        refPercent[2] = _percent3;
        refPercent[3] = _percent4;
    }

    function setRefLimit(
        uint256 _limit1,
        uint256 _limit2,
        uint256 _limit3
    ) external onlyOwner {
        refLimit[0] = _limit1;
        refLimit[1] = _limit2;
        refLimit[2] = _limit3;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changetoken(address _token) external onlyOwner {
        token = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns (bool) {
        owner.transfer(_value);
        return true;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function contractBalanceBnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContracttokenBalance() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}