pragma solidity ^0.4.24;

/// @dev Controlled
contract Controlled {

    // Controller address
    address public controller;

    /// @notice Checks if msg.sender is controller
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    /// @notice Constructor to initiate a Controlled contract
    constructor() public { 
        controller = msg.sender;
    }

    /// @notice Gives possibility to change the controller
    /// @param _newController Address representing new controller
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }

}

/// @dev ERC20 Interface
contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @dev Bond Whitelist
contract BondWhitelist is Controlled {

    // mapping showing if address is whitelisted or not
    mapping(address => bool) whitelisted;

    /// @notice Add address to whitelist
    /// @param _address Address to be whitelisted
    function add(address _address) onlyController public {
        whitelisted[_address] = true;
    }

    /// @notice Remove address from whitelist
    /// @param _address Address to be removed from whitelist
    function remove(address _address) onlyController public {
        whitelisted[_address] = false;
    }

    /// @notice Add multiple addresses to whitelist
    /// @param _addresses Addresses to be whitelisted
    function bulkAdd(address[] _addresses) onlyController public {
        for(uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    /// @notice Remove multiple addresses from whitelist
    /// @param _addresses Addresses to be removed from whitelist
    function bulkRemove(address[] _addresses) onlyController public {
        for(uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = false;
        }
    }

    /// @notice Check if address is whitelisted
    /// @param _address Address as a parameter to check
    /// @return True if address is whitelisted
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address];
    }

    /// @dev fallback function which prohibits payment
    function () public payable {
        revert();
    }

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == address(0)) {
            controller.transfer(address(this).balance);
            return;
        }

        ERC20Interface token = ERC20Interface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);

}