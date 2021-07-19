//SourceUnit: contract.sol

pragma solidity 0.5.9;
    
interface ITRC20 {
    function balanceOf(address who) external returns (uint);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns(bool);
}

contract BridgeOracle {
        
    event Log1(address sender, bytes32 cid, uint timeout, string _datasource, string _arg, uint feelimit, uint256 timestamp);
    event Log2(address sender, bytes32 cid, uint timeout, string _datasource, string _arg1, string _arg2, uint feelimit, uint256 timestamp);
    event logN(address sender, bytes32 cid, uint timeout, string _datasource, bytes args, uint feelimit, uint256 timestamp);
        
    event updatePrice(uint256 price, uint256 timestamp);
    event Emit_OffchainPaymentFlag(address indexed idx_sender, address sender, bool indexed idx_flag, bool flag);
        
    address internal paymentFlagger;
    mapping (address => bool) public offchainPayment;

    bool public usingToken;

    address public validBot;

    address private BRGaddr;

    function getReqc(address _client) public view returns (uint256 _count){
        require(msg.sender == cbAddress());
        return reqc[_client];
    }

    function setBRGaddr(address _newAddress) public onlyAdmin {
        BRGaddr = _newAddress;
    }

    modifier onlyPriceBot {
        require(validBot == msg.sender);
        _;
    }

    function submitPriceBot(address newBot) public onlyAdmin {
        validBot = newBot;
    }

    function getTokenPrice() public view returns(uint256 _price) {
        return tokenPrice;
    }

    uint256 public Rdec;
    function relativeDecimal(uint256 _decimal) public onlyAdmin {
        Rdec = _decimal;
    }

    function tokenPermission() public onlyAdmin {
        if(usingToken)
            usingToken = false;
        else
            usingToken = true;
    }

    function getTokenStatus() external view returns(bool _status) {
        return usingToken;
    }

    uint256 private tokenPrice;

    function setTokenPrice(uint256 _price) public onlyPriceBot {
        tokenPrice = _price;
        emit updatePrice(_price, now);
    }
        
    mapping(address => uint) internal reqc;
    mapping(address => byte) public cbAddresses;
    uint public basePrice;
    uint256 public maxBandWidthPrice; 
    uint256 public defaultFeeLimit;
    bytes32[] dsources;
    address private owner;
    mapping (bytes32 => uint) price_multiplier;
        
    constructor() public {
        owner = msg.sender;
    }
        
    function changeAdmin(address _newAdmin) external onlyAdmin {
        owner = _newAdmin;
    }
        
    function changePaymentFlagger(address _newFlagger) external onlyAdmin {
        paymentFlagger = _newFlagger;
    }
        
    function setOffchainPayment(address _addr, bool _flag) external {
        require(msg.sender == paymentFlagger);
        offchainPayment[_addr] = _flag;
        emit Emit_OffchainPaymentFlag(_addr, _addr, _flag, _flag);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == owner);
        _;
    }
    
    function setMaxBandWidthPrice(uint256 new_maxBandWidthPrice) external onlyAdmin {
        maxBandWidthPrice = new_maxBandWidthPrice;
    }

    function setDefaultFeeLimit(uint256 new_defaultFeeLimit) external onlyAdmin {
        defaultFeeLimit = new_defaultFeeLimit;
    }
        
    function addCbAddress(address newCbAddress, byte addressType) public onlyAdmin {
        cbAddresses[newCbAddress] = addressType;
    }
    
    function removeCbAddress(address newCbAddress) external onlyAdmin {
        delete cbAddresses[newCbAddress];
    }
    
    function addDSource(string memory dsname, uint multiplier) public onlyAdmin {
        bytes32 dsname_hash = sha256(abi.encodePacked(dsname));
        dsources[dsources.length++] = dsname_hash;
        price_multiplier[dsname_hash] = multiplier;
    }

    function removeDSource(string memory dsname) public onlyAdmin {
        bytes32 dsname_hash = sha256(abi.encodePacked(dsname));
        delete price_multiplier[dsname_hash];
        uint len = dsources.length;
        for(uint i = 0; i < len; i++){
            if(dsources[i] == dsname_hash) {
                dsources[i] = dsources[dsources.length - 1];
                delete dsources[dsources.length - 1];
                dsources.length--;
                break;
            }
        }
    }
    
    function cbAddress() public view returns(address _cbAddress) {
        if(cbAddresses[tx.origin] != 0)
            _cbAddress = tx.origin;
    }
    
    function setBasePrice(uint new_baseprice) external onlyAdmin {
        basePrice = new_baseprice;
        for (uint i =0; i< dsources.length; i++) price[dsources[i]] = new_baseprice*price_multiplier[dsources[i]];
    }
        
    function getPrice(string memory _datasource) public view returns(uint256 TRXbasedPrice, uint256 discountPrice) {
        return getPrice(_datasource, msg.sender);
    }
        
    function getPrice(string memory _datasource, uint _feeLimit) public view returns(uint256 TRXbasedPrice, uint256 discountPrice) {
        return getPrice(_datasource, _feeLimit, msg.sender);
    }
        
    function getPrice(string memory _datasource, address _addr) private view returns(uint256 TRXbasedPrice, uint256 discountPrice) {
        return getPrice(_datasource, defaultFeeLimit, _addr);
    }
        
    mapping (bytes32 => uint) price;


    uint256 public discount;


    function setDiscount(uint256 _amount) public onlyAdmin {
        require(_amount <= 100);
        discount = _amount;
    } 
        
    function getPrice(string memory _datasource, uint _feeLimit, address _addr) private view returns(uint TRXbasedPrice, uint discountPrice) {
        if(offchainPayment[_addr] || reqc[_addr] == 0) {
            return (0, 0);
        }
        require(_feeLimit <= defaultFeeLimit);
        uint256 _dsprice = price[sha256(abi.encodePacked(_datasource))];
        TRXbasedPrice = _dsprice + maxBandWidthPrice + _feeLimit;
        discountPrice = (_dsprice - ((_dsprice * discount) / 100)) + maxBandWidthPrice + _feeLimit;
        return (TRXbasedPrice, discountPrice);
    }
    
    function costs(string memory datasource, uint feelimit) private {
        (uint256 _TRXbasedPrice, uint256 _discountPrice) = getPrice(datasource, feelimit);
        address _owner = msg.sender;

        uint256 _tokenPrice = getTokenPrice();
        uint256 _tokenBasedPrice = (_discountPrice * _tokenPrice)/10 ** Rdec;
    
        if(usingToken && ITRC20(BRGaddr).balanceOf(_owner) >= _tokenBasedPrice){
            require(ITRC20(BRGaddr).transferFrom(_owner, address(this), _tokenBasedPrice));
        }
        else {
            if (msg.value >= _TRXbasedPrice) {
                uint diff  = msg.value - _TRXbasedPrice;
                if (diff > 0) {
                    require(msg.sender.send(diff));
                }
            } else
                revert();
        }
    }

    function getRelativeDecimal() external view returns(uint256 _dec) {
        return Rdec;
    }
        
    function withdrawFunds(address payable _addr) external onlyAdmin {
        _addr.transfer(address(this).balance);
    }

    function transferAnyTRC20(address _tokenAddress, address _to, uint256 _amount) public onlyAdmin {
        ITRC20(_tokenAddress).transfer(_to, _amount);
    }
    
    function query(string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id) {
        return query1(0, _datasource, _arg, defaultFeeLimit);
    }
        
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) payable external returns(bytes32 _id) {
        return query1(_timestamp, _datasource, _arg, defaultFeeLimit);
    }
    
    function query_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _feelimit) external payable returns(bytes32 _id) {
        return query1(_timestamp, _datasource, _arg, _feelimit);
    }
    
    function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns(bytes32 _id) {
        return query2(_timestamp, _datasource, _arg1, _arg2, defaultFeeLimit);
    }
    
    function query2_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _feeLimit) external payable returns(bytes32 _id) {
        return query2(_timestamp, _datasource, _arg1, _arg2, _feeLimit);
    }
    
    function queryN(string calldata _datasource, bytes calldata _args) external payable returns(bytes32 _id) {
        return queryN(0, _datasource, _args, defaultFeeLimit);
    }
    
    function queryN(uint _timestamp, string calldata _datasource, bytes calldata _args) external payable returns(bytes32 _id) {
        return queryN(_timestamp, _datasource, _args, defaultFeeLimit);
    }
    
    function query1(uint _timestamp, string memory _datasource, string memory _arg, uint _feeLimit) public payable returns(bytes32 _id) {
        costs(_datasource, _feeLimit);
        _id = sha256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit Log1(msg.sender, _id, _timestamp, _datasource, _arg, _feeLimit, now);
        return _id;
    }
    
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _feeLimit) public payable returns(bytes32 _id) {
        costs(_datasource, _feeLimit);
        _id = sha256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit Log2(msg.sender, _id, _timestamp, _datasource, _arg1, _arg2, _feeLimit, now);
        return _id;
    }
    
    function queryN(uint _timestamp, string memory _datasource, bytes memory _args, uint _feelimit) public payable returns(bytes32 _id) {
        costs(_datasource, _feelimit);
        _id = sha256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit logN(msg.sender, _id, _timestamp, _datasource, _args, _feelimit, now);
        return _id;
        }
}