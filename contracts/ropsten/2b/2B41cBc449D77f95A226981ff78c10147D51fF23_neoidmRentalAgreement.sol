//solium-disable linebreak-style
pragma solidity ^0.4.21;
//import "../TokenICO/baseToken.sol";

contract MintableToken {
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
}

contract neoidmRentalAgreement {
    /* This declares a new complex type which will hold the paid rents*/
    //struct PaidRent {
     //   uint id; /* The paid rent id*/
     //   uint value; /* The amount of rent that is paid*/
    //}

    //PaidRent[] public paidrents;

    //uint public createdTimestamp;

    MintableToken private token; /*neoidmToken address*/

    uint256 private timeCreated;/* contract creation time. seconds from unix epoch */

    uint256 private totalFee; /*total rental fee */
    uint256 private rate; /* rate per day */
    uint256 private from; /* rental starting time . seconds from unix epoch*/
    uint256 private to;
    uint256 private terminated;

    /*NeoIDM device endpoint*/
    string private endpoint;
    address private owner; /*contract owner*/
    address private tenant;
    bytes32 private contractKey;

    enum State {Created, Started, Terminated}
    State private state;
    
    /**
   * @param _created contract creation time
   * @param _token Address of the token being used
   * @param _tenant Address of the tenant
   * @param _total total rental fee(tenant should pay)
   * @param _rate rental fee(token amount) per day
   * @param _endpoint target device endpoint name
   * @param _from rental starting time
   */
    constructor(uint256 _created, address _token, address _tenant, uint256 _total, uint256 _rate, string _endpoint, uint256 _from) public {
        timeCreated = _created;
        from = _from;
        token = MintableToken(_token);
        tenant = _tenant;
        totalFee = _total;
        rate = _rate;
        endpoint = _endpoint;
        owner = msg.sender;
        state = State.Created;
        to = from + (totalFee/rate) * 1 days;
    }

    modifier onlyContractParties() {
        require (msg.sender == owner || msg.sender == tenant, "Sender and Owner must be one of contract parties");
        _;
    }
    modifier onlyOwner() {
        require (msg.sender == owner, "Sender and Owner must be identical");
        _;
    }
    modifier onlyTenant() {
        require (msg.sender == tenant, "It&#39;s not tenant");
        _;
    }
    modifier inState(State _state) {
        require (state == _state, "Different state");
        _;
    }

   
    function getTotalFee() public view returns (uint256) {
        return totalFee;
    }

    function getEndpoint() public view returns (string) {
        return endpoint;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getTenant() public view onlyContractParties() returns (address) 
    {
        return tenant;
    }

    function getCreated() public view returns (uint256) {
        return timeCreated;
    }

    function getFrom() public view returns (uint256) {
        return from;
    }
    function getTo() public view returns (uint256) {
        return to;
    }
    function getTerminated() public view returns (uint256) {
        return terminated;
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    /*function getContractCreated() public view returns (uint) {
        return createdTimestamp;
    }*/

    function getContractAddress() public view returns (address) {
        return this;
    }

    function getState() public view returns (State) {
        return state;
    }
    /* 액세스요청시 요청자와 key, 시간을 체크한다.
     */
    function validateTenant(address requester, bytes32 key, uint256 accesstime) public view onlyOwner() returns (bool) {
        if(requester == tenant && key == contractKey && state == State.Started && accesstime >= from && accesstime < to )
            return true;
        else
            return false;
    }   

    /* Events for DApps to listen to */
    //event agreementConfirmed();

    event rentSigned();

    event contractTerminated();

    /*function bytes32ToString(bytes32 x) public view returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }*/
    

    function rentSign(uint256 fee) public 
    inState(State.Created) 
    onlyTenant()
    returns (bytes32){
     
        require(fee < totalFee, "value is less than totalFee");
        require(totalFee <= token.balanceOf(msg.sender), "your balance is not enough");
    
        //token.transferFrom(tenant, owner, fee);
        token.transfer(owner, fee);
        state = State.Started;
        //random contractkey 생성하기...
        //contractkey = bytes32ToString(keccak256(msg.data));
        contractKey = keccak256(msg.data);
        emit rentSigned();

        return contractKey;
    }

    /* Terminate the contract so the tenant can’t pay rent anymore,
    and the contract is terminated */
    function terminateContract(uint256 reqtime) public
    onlyOwner()
    {
        if(state == State.Terminated)
            return;

        state = State.Terminated;
        terminated = reqtime;
        emit contractTerminated();

        //남은 잔액을 환급해준다.
        if(reqtime < to){
            uint256 refund = ((to - reqtime)/1 days)*rate;
            require(refund <= token.balanceOf(msg.sender), "your balance is not enough");
            token.transfer(tenant, refund);
        }

    }
}