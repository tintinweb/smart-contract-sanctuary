//SourceUnit: Relation.sol


pragma solidity >=0.5.0;

contract Initializable {


    bool private _initialized;


    bool private _initializing;


     //|| _isConstructor()
    modifier initializer() {
        require(_initializing  || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    function _isConstructor() private view returns (bool) {
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Verifiable is Ownable{

    mapping ( address => bool) public isAuthAddress;

    modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {size := extcodesize(safeAddr)}
        require( size == 0, "Sender Is Contract" );
        _;
    }

    modifier KDelegateMethod() {
        require(isAuthAddress[msg.sender], "PermissionDeny");
        _;
    }


    function KAuthAddress(address user,bool isAuth) external  onlyOwner returns (bool) {
        isAuthAddress[user] = isAuth;
        return true;
    }

}

contract Time is Ownable{


    function timestempZero() internal view returns (uint) {
        return timestemp() / 1 days * 1 days;
    }



    function timestemp() internal view returns (uint) {
        return now;
    }

}

contract Relation is Initializable,Verifiable,Time {

    event RelationEx(address indexed owner,uint indexed time,address recommer);
    event UserShareAward(address indexed owner,uint indexed time,uint amount);

    address internal constant rootAddress = address(0xdead);

    uint public totalAddresses;

    mapping (address => address) public _recommerMapping;

    mapping (address => address[]) internal _recommerList;

    uint256 public constant trxTicket = 300e6;
    uint internal constant shareAward = 30e6;

    struct User{
        uint unClaimShareAward;
        uint claimedShareAward;
        uint childs;
    }

    mapping(address => User) public users;

    struct Network{
        address payable receiver;
        uint unClaim;
        uint claimed;
    }

    Network public network;

    function initialize(
        address _receiver,
        address _ownerAddress
        ) external  initializer{

        _recommerMapping[rootAddress] = address(0xdeaddead);
        network = Network(address(uint160(_receiver)),0,0);

        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    function MigrateRelation(
        address[] calldata owners,
        address[] calldata recommers )external onlyOwner {

            require(owners.length == recommers.length,"param error");
            for( uint256 i = 0; i < owners.length; i++){
                _migrateRelation(owners[i],recommers[i]);
            }
    }

    function _migrateRelation(address owner,address recommer)internal{
        require(recommer != owner,"your_self");

        if( _recommerMapping[owner] == address(0x0)){
             totalAddresses++;
            _recommerMapping[owner] = recommer;
            _recommerList[recommer].push(owner);
        }
    }



    function _bindRelation(address owner,address recommer)internal{

         require(recommer != owner,"your_self");

         require(_recommerMapping[owner] == address(0x0),"binded");

        require(recommer == rootAddress || _recommerMapping[recommer] != address(0x0),"p_not_bind");


        totalAddresses++;


        _recommerMapping[owner] = recommer;
        _recommerList[recommer].push(owner);

    }

    function addRelationEx(address recommer) external payable KRejectContractCall returns (bool) {

        require( msg.value >= trxTicket, "UnableToPay");

        _bindRelation(msg.sender,recommer);

        uint totalShare = 0;

        for (
            (address parent, uint i) = (_recommerMapping[msg.sender], 0);
            i < 9 && parent != rootAddress;
            (i++, parent = _recommerMapping[parent])
        ) {

            if( _recommerList[parent].length > i ){
                users[parent].unClaimShareAward += shareAward;
                totalShare += shareAward;
            }
        }

        uint surplus = msg.value - totalShare;
        network.unClaim += surplus;
        return true;
    }

    function networkWithdraw(address to)external onlyOwner returns(uint){

        uint amount = network.unClaim;
        if( amount > 0){
            network.unClaim = 0;
            network.claimed += amount;
            address(uint160(to)).transfer(amount);
        }
        return amount;
    }

    function userWithdrawShare()external returns(bool){

        uint amount = users[msg.sender].unClaimShareAward;
        if( amount > 0 ){
            users[msg.sender].unClaimShareAward = 0;
            users[msg.sender].claimedShareAward += amount;
            msg.sender.transfer(amount);
            return true;
        }
    }

    function getChilds(address owner,uint offset,uint size)external view returns(address[] memory childs){

        address[] storage list = _recommerList[owner];

        childs = new address[](size);

        uint len = list.length;

        for( (uint i,uint k) = (offset,0); i < len && k < size; (i++,k++)){
            childs[k] = list[i];
        }
    }

    function getChildsLength(address owner) external view returns(uint256){
        return _recommerList[owner].length;
    }

    function getFarthers(address owner,uint num)external view returns(address[] memory farthers){

        farthers = new address[](num);

        for(
            (address parent,uint i) = (_recommerMapping[owner],0)
            ; parent != rootAddress && i < num
            ; ( parent =_recommerMapping[parent],i++ ))
            {

            farthers[i] = parent;
        }
    }


    function getRecommers(address[] calldata owners)external view returns(address[] memory recommers){

        uint len = owners.length;
        recommers = new address[](len);

        for( uint i = 0; i < len; i ++){
            address recommer = _recommerMapping[owners[i]];

            if( recommer != rootAddress){
                recommers[i] = recommer;
            }
        }
    }
}