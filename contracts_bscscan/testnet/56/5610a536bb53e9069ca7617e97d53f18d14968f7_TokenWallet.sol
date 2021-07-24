/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity 0.4.23;
/**
* @notice IAD Wallet Token Contract
* @dev ERC-20 Standard Compliant Token handler
*/

/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public

    /**
    * @dev Contract constructor
    * define initial administrator
    */
    constructor() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    //All admin actions have a log for public review
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    function name() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title Token wallet
* @dev ERC20 Token compliant
*/
contract TokenWallet is admined {

    /**
    * @notice token contructor.
    */
    constructor() public {    
    }

    event LogTokenAddedToDirectory(uint256 _index, string _name);
    event LogTokenTransfer(address _token, address _to, uint256 _amount);
    event LogTokenAllowanceApprove(address _token, address _to, uint256 _value);

    ERC20[] public tokenDirectory;
    string[] public tokenDirectoryName;

    /***************************
    * Token Directory functions*
    ****************************/

    function addTokenToDirectory(ERC20 _tokenContractAddress) onlyAdmin public returns (uint256){
        require(_tokenContractAddress != address(0));
        require(_tokenContractAddress.totalSupply() !=0 );
        uint256 index = tokenDirectory.push(_tokenContractAddress) - 1;
        tokenDirectoryName.push(_tokenContractAddress.name());
        emit LogTokenAddedToDirectory(index,_tokenContractAddress.name());
        return index;

    }
    
    function replaceDirectoryToken(ERC20 _tokenContractAddress, uint256 _directoryIndex) onlyAdmin public returns (uint256){
        require(_tokenContractAddress != address(0));
        require(_tokenContractAddress.totalSupply() !=0 );
        tokenDirectory[_directoryIndex] = _tokenContractAddress;
        tokenDirectoryName[_directoryIndex]= _tokenContractAddress.name();
        emit LogTokenAddedToDirectory(_directoryIndex,_tokenContractAddress.name());
    }

    function balanceOfDirectoryToken(uint256 _index) public view returns (uint256) {
        ERC20 token = tokenDirectory[_index];
        return token.balanceOf(address(this));
    }

    function transferDirectoryToken(uint256 _index, address _to, uint256 _amount) public onlyAdmin{
        ERC20 token = tokenDirectory[_index];
        //require(token.transfer(_to,_amount));
        token.transfer(_to,_amount);
        emit LogTokenTransfer(token,_to,_amount);
    }

    function batchTransferDirectoryToken(uint256 _index,address[] _target,uint256[] _amount) onlyAdmin public {
        require(_target.length >= _amount.length);
        uint256 length = _target.length;
        ERC20 token = tokenDirectory[_index];

        for (uint i=0; i<length; i++) { //It moves over the array
            token.transfer(_target[i],_amount[i]);
            emit LogTokenTransfer(token,_target[i],_amount[i]);       
        }
    }

    function giveDirectoryTokenAllowance(uint256 _index, address _spender, uint256 _value) onlyAdmin public{
        ERC20 token = tokenDirectory[_index];
        token.approve(_spender, _value);
        emit LogTokenAllowanceApprove(token,_spender, _value);
    }

    /*************************
    * General Token functions*
    **************************/

    function balanceOfToken (ERC20 _tokenContractAddress) public view returns (uint256) {
        ERC20 token = _tokenContractAddress;
        return token.balanceOf(this);
    }

    function transferToken(ERC20 _tokenContractAddress, address _to, uint256 _amount) public onlyAdmin{
        ERC20 token = _tokenContractAddress;
        //require(token.transfer(_to,_amount));
        token.transfer(_to,_amount);
        emit LogTokenTransfer(token,_to,_amount);
    }

    function batchTransferToken(ERC20 _tokenContractAddress,address[] _target,uint256[] _amount) onlyAdmin public {
        require(_target.length >= _amount.length);
        uint256 length = _target.length;
        ERC20 token = _tokenContractAddress;

        for (uint i=0; i<length; i++) { //It moves over the array
            token.transfer(_target[i],_amount[i]);
            emit LogTokenTransfer(token,_target[i],_amount[i]);       
        }
    }

    function giveTokenAllowance(ERC20 _tokenContractAddress, address _spender, uint256 _value) onlyAdmin public{
        ERC20 token = _tokenContractAddress;
        token.approve(_spender, _value);
        emit LogTokenAllowanceApprove(token,_spender, _value);
    }


    /**
    * @notice this contract will revert on direct non-function calls, also it's not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

}