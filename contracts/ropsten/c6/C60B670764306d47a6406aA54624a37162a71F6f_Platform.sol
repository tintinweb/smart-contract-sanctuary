pragma solidity ^0.4.23;

contract Platform {
    
    /**
    @notice constructor of contract
    */
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    @notice change of ownership
    @param _newOwner address of new contract owner
    */
    function ownerTransfership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    address public owner;
    uint256 public minimal = 1000 ether;
    mapping (address => bool) gamelist;
    mapping (address => uint) whitelist;

    /**
    @notice Set the launch permission
    @param _game address of the game
    @return success
    */
    function addGame(address _game) public onlyOwner returns(bool success) {
        gamelist[_game] = true;
        success = true;
    }

    /**
    @notice Delete the launch permission
    @param _game address of the game
    @return success
    */
    function delGame(address _game) public onlyOwner returns(bool success) {
        gamelist[_game] = false;
        success = true;
    }

    /**
    @notice Get the launch permission
    @param _game address of the game
    @return game status
    */
    function getStatus(address _game) external view returns(bool status) {
        status = gamelist[_game];
    }

    mapping(address => address) public referrerOf;
    mapping(address => address) public operatorOf;
    mapping(address => uint) public referrerCount;
    uint public users = 0;



    /**
    @notice Player registration
    @param _player Player address
    @param _referrer Referrer address
    */
    function setService(address _player, address _referrer) public {
        require(msg.sender == owner);
        require(referrerOf[_player] == address(0) && operatorOf[_player] == address(0)); 
        referrerCount[_referrer]++;
        users++;
        if (_referrer != address(0)) {
            referrerOf[_player] = _referrer;
        } else {
            referrerOf[_player] = msg.sender;   
        }
        operatorOf[_player] = msg.sender;
    }

    /** 
    @notice Get address of operator and referrer
    @param _player Address of player
    @return {
      "_operator": "The operator address to receive a reward",
      "_referrer": "The referrer address to receive a reward"
    }
    */
    function getService(address _player) external view returns(address _operator, address _referrer) {
        return (operatorOf[_player], referrerOf[_player]);
    }

    /** 
    @notice Get address of referrer
    @param _player Address of player
    @return The referrer address to receive a reward
    */
    function getReferrer(address _player) external view returns(address _referrer) {
        return referrerOf[_player];
    }

    /** 
    @notice Get address of operator (platform)
    @param _player Address of player
    @return The operator address to receive a reward
    */
    function getOperator(address _player) external view returns(address _operator) {
        return operatorOf[_player];
    }

    /**
    @notice Set the allowed amount
    @param _player address of the player
    @param _amount allowable amount
    @return success
    */
    function setAmountForPlayer(address _player, uint _amount) public onlyOwner returns(bool) {
        whitelist[_player] = _amount;
        return true;
    }

    /**
    @notice Get the allowed amount
    @param _player address of the player
    @return allowable amount
    */
    function getMaxAmount(address _player) external view returns(uint _amount) {
        _amount = whitelist[_player];
        if (_amount == uint(0)) {
            _amount = minimal;
        }
    }

}