/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// File: @openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol

// 

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// File: ..\..\node_modules\@openzeppelin\contracts\utils\Context.sol

// 

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts\newMarketplaceProxy.sol

// 
pragma solidity  ^0.8.4;



// contract Thing is Initializable, Ownable {

//   string public name;

//   /**
//   * @dev Logic contract that proxies point to
//   * @param _name name
//   * @param _owner The address of the thing owner
//   */

//   function initialize(string memory _name, address _owner) public {
//     Ownable.initialize(_owner);
//     name = _name;
//   }
// }

// Adding ERC-20 tokens function for added balanceOfcontract MarketplaceToken {
//contract MarketplaceToken {
    //function transfer(address _to, uint _value) public returns (bool success);
    //function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    //function approve(address _spender, uint _value) public returns (bool success);
//}

// Adding only ERC-20 DAI functions that we need //0x727C4e8577b315C87697810e4fE4a27efC5463c6

interface MarketplaceToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value)external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address owner, address spender) external returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INFT {
    function arbitratorAddress() external view returns(address);
    function ownerAddress() external view returns(address);
    function getTokenOwner  (string memory _id) external view returns (address);
    function mintNFT(string memory tokenUri, string memory _id) external returns (uint256);
    function mintNFTSave(string memory tokenUri, string memory _id, address to) external returns (uint256);
    function internalTransfer(address to, string memory _id, bytes32 data) external returns(bool success);
    function directTransfer(address to, string memory _id) external returns(uint256);
    function userTokens(address to) external;
    function burn (string memory _id) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function approveTokenToAddress(address to, string memory _id) external;
    function getTotalTokenOwner(address to) external view returns(uint256);
}

contract Dai{
    MarketplaceToken daitoken;

    constructor(){
        daitoken =  MarketplaceToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);     // Kovan
        //daitoken = DaiInterface(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);    // Rinkeby
        //daitoken = DaiInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);    // ETH Mainnet
        //daitoken = DaiInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);    // BSC Mainnet
    }
}

contract Treks{
    MarketplaceToken trekstoken;

    constructor(){
        trekstoken = MarketplaceToken(0x15492208Ef531EE413BD24f609846489a082F74C);
    }
}


contract PlaytreksMarketplaceProxy is Dai, Treks, Initializable, Ownable {
    address public creator = msg.sender; // can withdraw funds after the successful is successfully funded and finished
    uint public start = block.timestamp;
    uint public end = block.timestamp + 60; // 1 min 
    Logs[] public trans;
    address[] public arbitrator;
    address public theOwner = address(0);
    address public relayer;
    uint32 public requestCancellationMinimumTime;
    uint256 public feesAvailableForWithdraw;

    struct Client {
        uint amountSent;
        bool exists;
        uint clientIndex;
    }
    
    struct Logs{
        address receiver;
        uint256 amount;
    }
    
    struct Escrow {
        // Set so we know the trade has already been created
        bool exists;
        // 1 = unlimited cancel time
        uint32 sellerCanCancelAfter;
        // The total cost of gas spent by relaying parties. This amount will be
        // refunded/paid to playtreks once the escrow is finished.
        uint128 totalGasFeesSpentByRelayer;
        // nft address for the escrow
        bytes32 nft;
        
        //GenNFTInterface genft; //contract for the nft contract
    }

    mapping(address => Client) public clientStructs;
    // Mapping of active trades. Key is a hash of the trade data
    mapping (bytes32 => Escrow) public escrows;
    mapping(address=> uint) public shares;
    address[] public clientList;
    
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);
    event Returned(address indexed to, uint amount);
    event Balance(uint amount);
    event Created(bytes32 _tradeHash);
    
    // constructor (){
    //     owner = msg.sender;
    //     arbitrator.push(msg.sender);
    //     relayer = msg.sender;
    //     requestCancellationMinimumTime =  1 hours;
    // }
    
    function initialize( address _owner) public {
        //Ownable.initialize(_owner);
        require(theOwner == address(0));
        theOwner = _owner;
        arbitrator.push(msg.sender);
         arbitrator.push(_owner);
        relayer = _owner;
        requestCancellationMinimumTime =  1 hours;
    }
    
    function buywithEth(uint256 agreedAmount, string memory _id, address nftContract) payable public {
        uint256 amount = msg.value;
        require(amount > 0, "You need to send some ether");
        require(amount >= agreedAmount, "Not enough Eth sent for purchase of nft");
        
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract);
        
        //transfer the nft to the new owner
        Nft.directTransfer(msg.sender, _id);

        address currentOwner = Nft.getTokenOwner(_id);
        //pay to nft owner account and taxes and royalties
        if(Nft.ownerAddress() == msg.sender){
            currentOwner.call{value: (amount*95)/100}("");
            //trekstoken.transfer(owner, (amount*95)/100)
        }else{
            currentOwner.call{value: (amount*90)/100}("");
            Nft.ownerAddress().call{value: (amount*5)/100}("");
            //trekstoken.transfer(owner, (amount*90)/100)
            //trekstoken.transfer(original, (amount*5)/100)
        }

        //address treksWallet = 0x05b2DCeDEe832Ba4ae7631cD1fF6E5Fc2c88037C;
        //pay remaining commision to PlayTreks wallet
        theOwner.call{value: (amount*5)/100}("");
        //trekstoken.transfer(0x05b2DCeDEe832Ba4ae7631cD1fF6E5Fc2c88037C, (amount/5))

    }
    
    //frontend
    function buyWithToken(uint256 amount, string memory _id,  address nftContract, bool types) public{
        require(amount > 0, "You need to send at least some tokens");
        uint256 allowance = trekstoken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract);
        address currentOwner = Nft.getTokenOwner(_id);

        // types == true means treks token is used for payment, false means dai token is used for payment
        if(types == true){

            //pay to nft owner account and taxes and royalties
            if(Nft.ownerAddress() == msg.sender){
                trekstoken.transferFrom(msg.sender, currentOwner, (amount*95)/100);
                //trekstoken.transfer(currentOwner, (amount*95)/100);
            }else{
                trekstoken.transferFrom(msg.sender, currentOwner, (amount*90)/100);
                trekstoken.transferFrom(msg.sender, Nft.ownerAddress(), (amount*5)/100);
                //trekstoken.transfer(currentOwner, (amount*90)/100);
                //trekstoken.transfer(Nft.ownerAddress(), (amount*5)/100);
            }

            //transfer the nft to the new owner
            Nft.directTransfer(msg.sender, _id);

            //pay remaining commision to PlayTreks wallet
            trekstoken.transferFrom(msg.sender, theOwner, (amount/5));
            //trekstoken.transfer(owner, (amount/5));
        }else{
    
            //pay to nft owner account and taxes and royalties
            if(Nft.ownerAddress() == msg.sender){
                daitoken.transferFrom(msg.sender, currentOwner, (amount*95)/100);
                //daitoken.transfer(currentOwner, (amount*95)/100);
            }else{
                daitoken.transferFrom(msg.sender, currentOwner, (amount*90)/100);
                daitoken.transferFrom(msg.sender, Nft.ownerAddress(), (amount*5)/100);
                //daitoken.transfer(currentOwner, (amount*90)/100);
                //daitoken.transfer(Nft.ownerAddress(), (amount*5)/100);
            }
            //transfer the nft to the new owner
            Nft.directTransfer(msg.sender, _id);
            
            //pay remaining commision to PlayTreks wallet
            daitoken.transferFrom(msg.sender, theOwner, (amount/5));
            //daitoken.transfer(owner, (amount/5));
        }
        
    }

    
    
    function setArbitrator(address _newArbitrator) onlyArbitrator external {
        /**
         * Set the arbitrator to a new address. Only the owner can call this.
         * @param address _newArbitrator
         */
        arbitrator.push(_newArbitrator);
    }

    function setOwner(address _newOwner) onlyArbitrator external {
        /**
         * Change the owner to a new address. Only the owner can call this.
         * @param address _newOwner
         */
        theOwner = _newOwner;
    }

    function setRelayer(address _newRelayer) onlyArbitrator external {
        /**
         * Change the relayer to a new address. Only the owner can call this.
         * @param address _newRelayer
         */
        relayer = _newRelayer;
    }

    function setRequestCancellationMinimumTime(uint32 _newRequestCancellationMinimumTime) onlyArbitrator external {
        /**
         * Change the requestCancellationMinimumTime. Only the owner can call this.
         * @param uint32 _newRequestCancellationMinimumTime
         */
        requestCancellationMinimumTime = _newRequestCancellationMinimumTime;
    }

    function contractAddress() public view returns(address){
        return address(this);
    }

    modifier onlyArbitrator {
        bool yes = false;
        for (uint i=0; i<arbitrator.length; i++) {
            if(msg.sender == arbitrator[i]){
                yes=true;
            }
        }
        require(yes == true, "Only approved arbitrators can call this function");
        _;
    }
    
    // modifier so that only the project creator can call certain functions
    modifier onlyCreator (address _contract){
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(_contract);
        
        bool yes = false;
        for (uint i=0; i<arbitrator.length; i++) {
            if(msg.sender == arbitrator[i]){
                yes=true;
            }
        }
        
        require (Nft.ownerAddress() == msg.sender || Nft.arbitratorAddress() == msg.sender || yes == true, "Unauthorized");
        _;
    }
}