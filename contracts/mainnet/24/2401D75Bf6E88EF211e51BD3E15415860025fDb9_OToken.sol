/**

* MIT License
* ===========
* 
* Copyright (c) 2020 OLegacy
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.5.17;

import "./Ownership.sol";
import "./Address.sol";
import "./ERC20Interface.sol";
import "./SafeERC20.sol";


library SafeMath {
    /**
        The MIT License (MIT)

        Copyright (c) 2016-2020 zOS Global Limited

        Permission is hereby granted, free of charge, to any person obtaining
        a copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    */


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) external;
}

/**
 * @title OToken
 * @author OLegacy
 */
contract OToken is ERC20Interface, Ownership {

    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20Interface;

    // State variables
    string public constant name = 'O Token'; // Name of token
    string public constant symbol = 'OT';  // Symbol of token
    uint256 public constant decimals = 8; // Decimals in token
    address public deputyOwner; // to perform tasks on behalf of owner in automated applications
    uint256 public totalSupply = 0; // initially totalSupply 0

    // external wallet addresses
    address public suspenseWallet; // the contract resposible for burning tokens
    address public centralRevenueWallet; // platform wallet to collect commission
    address public minter; // adddress of minter

    // to hold commissions on each token transfer
    uint256 public commission_numerator; // commission percentage numerator
    uint256 public commission_denominator;// commission percentage denominator

    // mappings
    mapping (address => uint256) balances; // balances mapping to hold OT balance of address
    mapping (address => mapping (address => uint256) ) allowed; // mapping to hold allowances

    mapping (address => bool) public isTaxFreeSender; // tokens transferred from these users won't be taxed
    mapping (address => bool) public isTaxFreeRecipeint; // if token transferred to these addresses won't be taxed
    mapping (string => mapping(string => bool)) public sawtoothHashMapping;
    mapping (address => bool) public trustedContracts; // contracts on which tokenFallback will be called

    // events
    event MintOrBurn(address _from, address to, uint256 _token, string sawtoothHash, string orderId );
    event CommssionUpdate(uint256 _numerator, uint256 _denominator);
    event TaxFreeUserUpdate(address _user, bool _isWhitelisted, string _type);
    event TrustedContractUpdate(address _contractAddress, bool _isActive);
    event MinterUpdated(address _newMinter, address _oldMinter);
    event SuspenseWalletUpdated(address _newSuspenseWallet, address _oldSuspenseWallet);
    event DeputyOwnerUpdated(address _oldOwner, address _newOwner);
    event CRWUpdated(address _newCRW, address _oldCRW);

    constructor (address _minter, address _crw, address _newDeputyOwner)
        public
        onlyNonZeroAddress(_minter)
        onlyNonZeroAddress(_crw)
        onlyNonZeroAddress(_newDeputyOwner)
    {
        owner = msg.sender; // set owner address to be msg.sender
        minter = _minter; // set minter address
        centralRevenueWallet = _crw; // set central revenue wallet address
        deputyOwner = _newDeputyOwner; // set deputy owner
        commission_numerator = 1; // set commission
        commission_denominator = 100;
        // emit proper events
        emit MinterUpdated(_minter, address(0));
        emit CRWUpdated(_crw, address(0));
        emit DeputyOwnerUpdated(_newDeputyOwner, address(0));
        emit CommssionUpdate(1, 100);
    }


    // Modifiers
    modifier canBurn() {
        require(msg.sender == suspenseWallet, "only suspense wallet is allowed");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter,"only minter is allowed");
        _;
    }

    modifier onlyDeputyOrOwner() {
        require(msg.sender == owner || msg.sender == deputyOwner, "Only owner or deputy owner is allowed");
        _;
    }

    modifier onlyNonZeroAddress(address _user) {
        require(_user != address(0), "Zero address not allowed");
        _;
    }

    modifier onlyValidSawtoothEntry(string memory _sawtoothHash, string memory _orderId) {
        require(!sawtoothHashMapping[_sawtoothHash][_orderId], "Sawtooth hash amd orderId combination already used");
        _;
    }
 
 
    ////////////////////////////////////////////////////////////////
    //                  Public Functions
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Standard transfer function to Transfer token
     * @dev The commission will be charged on top of _value
     * @param _to recipient address
     * @param _value amount of tokens to be transferred to recipient
     * @return Bool value
     */ 
    function transfer(address _to, uint256 _value) public returns (bool) {
        return privateTransfer(msg.sender, _to, _value, false, false); // internal method
    }

    /**
     * @notice Alternate method to standard transfer with fee deducted from transfer amount
     * @dev The commission will be deducted from _value
     * @param _to recipient address
     * @param _value amount of tokens to be transferred to recipient
     * @return Bool value
     */ 
    function transferIncludingFee(address _to, uint256 _value)
        public
        onlyNonZeroAddress(_to)
        returns(bool)
    {
        return privateTransfer(msg.sender, _to, _value, false, true);
    }

    /**
     * @notice Bulk transfer
     * @dev The commission will be charged on top of _value
     * @param _addressArr array of recipient address
     * @param _amountArr array of amounts corresponding to index on _addressArr
     * @param _includingFees Denotes if fee should be deducted from amount or added to amount
     * @return Bool value
     */ 
    function bulkTransfer (address[] memory _addressArr, uint256[] memory _amountArr, bool _includingFees) public returns (bool) {
        require(_addressArr.length == _amountArr.length, "Invalid params");
        for(uint256 i = 0 ; i < _addressArr.length; i++){
            uint256 _value = _amountArr[i];
            address _to = _addressArr[i];
            privateTransfer(msg.sender, _to, _value, false, _includingFees); // internal method
        }
        return true;
    }
    
    /**
     * @notice Standard Approve function
     * @dev This suffers from race condition. Use increaseApproval/decreaseApproval instead
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _value amount of token allowed
     * @return Bool value
     */ 
    function approve(address _spender, uint256 _value) public returns (bool) {
        return _approve(msg.sender, _spender, _value);
    }

    /**
     * @notice Increase allowance
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _addedValue amount by which allowance needs to be increased
     * @return Bool value
     */ 
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
       return _increaseApproval(msg.sender, _spender, _addedValue);
    }
  
    /**
     * @notice Decrease allowance
     * @dev if the _subtractedValue is more than previous allowance, allowance will be set to 0
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _subtractedValue amount by which allowance needs to be decreases
     * @return Bool value
     */ 
    function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool) {
        return _decreaseApproval(msg.sender, _spender, _subtractedValue);
    }
    
    /**
     * @notice Approve and call
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _value amount of token allowed
     * @param _extraData The extra data that will be send to recipient contract
     * @return Bool value
     */ 
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, address(this), _extraData);
                return true;
        }else{
            return false;
        }
    }

    /**
     * @notice Standard transferFrom. Send tokens on behalf of spender
     * @dev from must have allowed msg.sender atleast _value to spend
     * @param _from Spender which has allowed msg.sender to spend on his behalf
     * @param _to Recipient to which tokens are to be transferred
     * @param _value The amount of token that will be transferred
     * @return Bool value
     */ 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender] ,"Insufficient approval");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        privateTransfer(_from, _to, _value, false, false);
    }


   
    ////////////////////////////////////////////////////////////////
    //                  Special User functions
    ////////////////////////////////////////////////////////////////
    /**
     * @notice Mint function.
     * @dev Only minter address is allowed to mint
     * @param _to The address to which tokens will be minted
     * @param _value No of tokens to be minted
     * @param _sawtoothHash The hash on sawtooth blockchain to track complete token generation cycle
     * @return Bool value
     */
    function mint(address _to, uint256 _value, string memory _sawtoothHash, string memory _orderId)
        public
        onlyMinter
        onlyNonZeroAddress(_to)
        onlyValidSawtoothEntry(_sawtoothHash, _orderId)
        returns (bool)
    {
        sawtoothHashMapping[_sawtoothHash][_orderId] = true;
        totalSupply = totalSupply.add(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(address(0), _to, _value);
        emit MintOrBurn(address(0), _to, _value, _sawtoothHash, _orderId);
        return true;

    }

    /**
     * @notice Bulk Mint function.
     * @dev Only minter address is allowed to mint
     * @param _addressArr The array of address to which tokens will be minted
     * @param _amountArr The array of tokens that will be minted
     * @param _sawtoothHash The hash on sawtooth blockchain to track complete token generation cycle
     * @param _orderId The id of order in sawtooth blockchain
     * @return Bool value
     */
    function bulkMint (address[] memory _addressArr, uint256[] memory _amountArr, string memory _sawtoothHash, string memory _orderId)
        public
        onlyMinter
        onlyValidSawtoothEntry(_sawtoothHash, _orderId)
        returns (bool)
    {
        require(_addressArr.length == _amountArr.length, "Invalid params");
        for(uint256 i = 0; i < _addressArr.length; i++){
            uint256 _value = _amountArr[i];
            address _to = _addressArr[i];
            
            require(_to != address(0),"Zero address not allowed");
            totalSupply = totalSupply.add(_value);
            balances[_to] = balances[_to].add(_value);
            sawtoothHashMapping[_sawtoothHash][_orderId] = true;
            emit Transfer(address(0), _to, _value);
            emit MintOrBurn(address(0), _to, _value, _sawtoothHash, _orderId);
        }
        return true;

    }

    /**
     * @notice Standard burn function.
     * @dev Only address allowd can burn
     * @param _value No of tokens to be burned
     * @param _sawtoothHash The hash on sawtooth blockchain to track gold withdrawal
     * @param _orderId The id of order in sawtooth blockchain
     * @return Bool value
     */
    function burn(uint256 _value, string memory _sawtoothHash, string memory _orderId)
        public
        canBurn
        onlyValidSawtoothEntry(_sawtoothHash, _orderId)
        returns (bool)
    {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        sawtoothHashMapping[_sawtoothHash][_orderId] = true;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0), _value);
        emit MintOrBurn(msg.sender, address(0), _value, _sawtoothHash, _orderId);
        return true;
    }

    /**
     * @notice Add/Remove a whitelisted recipient. Token transfer to this address won't be taxed
     * @dev Only Deputy owner can call
     * @param _users The array of addresses to be whitelisted/blacklisted
     * @param _isSpecial true means user will be added; false means user will be removed
     * @return Bool value
     */
    function updateTaxFreeRecipient(address[] memory _users, bool _isSpecial)
        public
        onlyDeputyOrOwner
        returns (bool)
    {
        for(uint256 i=0; i<_users.length; i++) {
            require(_users[i] != address(0), "Zero address not allowed");
            isTaxFreeRecipeint[_users[i]] = _isSpecial;
            emit TaxFreeUserUpdate(_users[i], _isSpecial, 'Recipient');
        }
        
        return true;
    }

    /**
     * @notice Add/Remove a whitelisted sender. Token transfer from this address won't be taxed
     * @dev Only Deputy owner can call
     * @param _users The array of addresses to be whitelisted/blacklisted
     * @param _isSpecial true means user will be added; false means user will be removed
     * @return Bool value
     */
    function updateTaxFreeSender(address[] memory _users, bool _isSpecial)
        public
        onlyDeputyOrOwner
        returns (bool)
    {
        for(uint256 i=0; i<_users.length; i++) {
            require(_users[i] != address(0), "Zero address not allowed");
            isTaxFreeSender[_users[i]] = _isSpecial;
            emit TaxFreeUserUpdate(_users[i], _isSpecial, 'Sender');
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////
    //                  Only Owner functions
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Add Suspense wallet address. This can be updated again in case of suspense contract is upgraded.
     * @dev Only owner can call
     * @param _suspenseWallet The address suspense wallet
     * @return Bool value
     */
    function addSuspenseWallet(address _suspenseWallet)
        public
        onlyOwner
        onlyNonZeroAddress(_suspenseWallet)
        returns (bool)
    {
        emit SuspenseWalletUpdated(_suspenseWallet, suspenseWallet);
        suspenseWallet = _suspenseWallet;
        return true;
    }

    /**
     * @notice Add Minter wallet address. This address will be responsible for minting tokens
     * @dev Only owner can call
     * @param _minter The address of minter wallet
     * @return Bool value
     */
    function updateMinter(address _minter)
        public
        onlyOwner
        onlyNonZeroAddress(_minter)
        returns (bool)
    {
        emit MinterUpdated(_minter, minter);
        minter = _minter;
        return true;
    }

    /**
     * @notice Add/Remove trusted contracts. The trusted contracts will be notified in case of tokens are transferred to them
     * @dev Only owner can call and only contract address can be added
     * @param _contractAddress The address of trusted contract
     * @param _isActive true means whitelited; false means blackkisted
     */
    function addTrustedContracts(address _contractAddress, bool _isActive) public onlyDeputyOrOwner {
        require(_contractAddress.isContract(), "Only contract address can be added");
        trustedContracts[_contractAddress] = _isActive;
        emit TrustedContractUpdate(_contractAddress, _isActive);
    }

    /**
     * @notice Update commission to be charged on each token transfer
     * @dev Only owner can call
     * @param _numerator The numerator of commission
     * @param _denominator The denominator of commission
     */
    function updateCommssion(uint256 _numerator, uint256 _denominator)
        public
        onlyDeputyOrOwner
    {
        commission_denominator = _denominator;
        commission_numerator = _numerator;
        emit CommssionUpdate(_numerator, _denominator);
    }

    /**
     * @notice Update deputy owner. The Hot wallet version of owner
     * @dev Only owner can call
     * @param _newDeputyOwner The address of new deputy owner
     */
    function updateDeputyOwner(address _newDeputyOwner)
        public
        onlyOwner
        onlyNonZeroAddress(_newDeputyOwner)
    {
        emit DeputyOwnerUpdated(_newDeputyOwner, deputyOwner);
        deputyOwner = _newDeputyOwner;
    }


    /**
     * @notice Update central revenue wallet
     * @dev Only owner can call
     * @param _newCrw The address of new central revenue wallet
     */
    function updateCRW(address _newCrw)
        public
        onlyOwner
        onlyNonZeroAddress(_newCrw)
    {
        emit CRWUpdated(_newCrw, centralRevenueWallet);
        centralRevenueWallet = _newCrw;
    }

    /**
     * @notice  Owner can transfer out any accidentally sent ERC20 tokens
     * @param _tokenAddress The contract address of ERC-20 compitable token
     * @param _value The number of tokens to be transferred to owner
     */
    function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner {
        ERC20Interface(_tokenAddress).safeTransfer(owner, _value);
    }



    ////////////////////////////////////////////////////////////////
    //                  Internal/ Private methods
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Internal method to handle transfer logic
     * @dev Notifies recipient, if recipient is a trusted contract
     * @param _from Sender address
     * @param _to Recipient address
     * @param _amount amount of tokens to be transferred
     * @param _withoutFees If true, commission will not be charged
     * @param _includingFees Denotes if fee should be deducted from amount or added to amount
     * @return bool
     */
    function privateTransfer(address _from, address _to, uint256 _amount, bool _withoutFees, bool _includingFees)
        internal
        onlyNonZeroAddress(_to)
        returns (bool)
    {
        uint256 _amountToTransfer = _amount;
        if(_withoutFees || isTaxFreeTx(_from, _to)) {
            require(balances[_from] >= _amount, "Insufficient balance");
            _transferWithoutFee(_from, _to, _amountToTransfer);
        } else {
            uint256 fee = calculateCommission(_amount);

            if(_includingFees) {
                require(balances[_from] >= _amount, "Insufficient balance");
                _amountToTransfer = _amount.sub(fee);
            } else {
                require(balances[_from] >= _amount.add(fee), "Insufficient balance");
            }
            if(fee > 0 ) _transferWithoutFee(_from, centralRevenueWallet, fee);
            _transferWithoutFee(_from, _to, _amountToTransfer);
        }
        notifyTrustedContract(_from, _to, _amountToTransfer);
        return true;
    }


    /**
     * @notice Internal method to facilitate token approval
     * @param _sender The user which allows _spender to spend on his behalf
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _value amount of token allowed
     * @return Bool value
     */ 
    function _approve(address _sender, address _spender, uint256 _value)
        internal returns (bool)
    {
        allowed[_sender][_spender] = _value;
        emit Approval (_sender, _spender, _value);
        return true;
    }

   /**
     * @notice Internal method to Increase allowance
     * @param _sender The user which allows _spender to spend on his behalf
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _addedValue amount by which allowance needs to be increased
     * @return Bool value
     */ 
    function _increaseApproval(address _sender, address _spender, uint256 _addedValue)
        internal returns (bool)
    {
        allowed[_sender][_spender] = allowed[_sender][_spender].add(_addedValue);
        emit Approval(_sender, _spender, allowed[_sender][_spender]);
        return true;
    }

    /**
     * @notice Internal method to Decrease allowance
     * @dev if the _subtractedValue is more than previous allowance, allowance will be set to 0
     * @param _sender The user which allows _spender to spend on his behalf
     * @param _spender The user which is allowed to spend on behalf of msg.sender
     * @param _subtractedValue amount by which allowance needs to be decreases
     * @return Bool value
     */
    function _decreaseApproval (address _sender, address _spender, uint256 _subtractedValue )
        internal returns (bool)
    {
        uint256 oldValue = allowed[_sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[_sender][_spender] = 0;
        } else {
            allowed[_sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(_sender, _spender, allowed[_sender][_spender]);
        return true;
    }

    /**
     * @notice Internal method to transfer tokens without commission
     * @param _from Sender address
     * @param _to Recipient address
     * @param _amount amount of tokens to be transferred
     * @return Bool value
     */
    function _transferWithoutFee(address _from, address _to, uint256 _amount)
        private
        returns (bool)
    {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }


    /**
     * @notice Notifies recipient about transfer only if recipient is trused contract
     * @param _from Sender address
     * @param _to Recipient contract address
     * @param _value amount of tokens to be transferred
     * @return Bool value
     */
    function notifyTrustedContract(address _from, address _to, uint256 _value) internal {
        // if the contract is trusted, notify it about the transfer
        if(trustedContracts[_to]) {
            TokenRecipient trustedContract = TokenRecipient(_to);
            trustedContract.tokenFallback(_from, _value, '0x');
        }

    }

    ////////////////////////////////////////////////////////////////
    //                  Public View functions
    ////////////////////////////////////////////////////////////////

  
    /**
     * @notice Get allowance from token owner to spender
     * @param _tokenOwner The token owner
     * @param _spender The user which is allowed to spend
     * @return uint256 Remaining allowance
     */
    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }


    /**
     * @notice Get balance of user
     * @param _tokenOwner User address
     * @return uint256 Current token balance
     */
    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    }

    /**
     * @notice check transer fee
     * @dev Does not checks if sender/recipient is whitelisted
     * @param _amount The intended amount of transfer
     * @return uint256 Calculated commission
     */
    function calculateCommission(uint256 _amount) public view returns (uint256) {
        return _amount.mul(commission_numerator).div(commission_denominator).div(100);
    }

    /**
     * @notice Checks if transfer between parties will be taxed or not
     * @param _from Sender address
     * @param _to Recipient address
     * @return bool true if no commission will be charged
     */
    function isTaxFreeTx(address _from, address _to) public view returns(bool) {
        if(isTaxFreeRecipeint[_to] || isTaxFreeSender[_from]) return true;
        else return false;
    }

    /**
     * @notice Prevents contract from accepting ETHs
     * @dev Contracts can still be sent ETH with self destruct. If anyone deliberately does that, the ETHs will be lost
     */
    function () external payable {
        revert("Contract does not accept ethers");
    }
}


/**
 * @title AdvancedOToken
 * @author OLegacy
 */    
contract AdvancedOToken is OToken {
    mapping(address => mapping(bytes32 => bool)) public tokenUsed; // mapping to track token is used or not
    
    bytes4 public methodWord_transfer = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 public methodWord_approve = bytes4(keccak256("approve(address,uint256)"));
    bytes4 public methodWord_increaseApproval = bytes4(keccak256("increaseApproval(address,uint256)"));
    bytes4 public methodWord_decreaseApproval = bytes4(keccak256("decreaseApproval(address,uint256)"));


    constructor(address minter, address crw, address deputyOwner) public OToken(minter, crw, deputyOwner) {
    }

    /**
        
     */
    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @notice Delegated Bulk transfer. Gas fee will be paid by relayer
     * @param message The message that user signed
     * @param r Signature component
     * @param s Signature component
     * @param v Signature component
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to relayer for gas fee he spends
     * @param _addressArr The array of recipients
     * @param _amountArr The array of amounts to be transferred
     * @param _includingFees Denotes if fee should be deducted from amount or added to amount
     * @return Bool value
     */
    function preAuthorizedBulkTransfer(
        bytes32 message, bytes32 r, bytes32 s, uint8 v, bytes32 token, uint256 networkFee, address[] memory _addressArr,
        uint256[] memory _amountArr, bool _includingFees )
        public
        returns (bool)
    {
        require(_addressArr.length == _amountArr.length, "Invalid params");

        bytes32 proof = getProofBulkTransfer(
            token, networkFee, msg.sender, _addressArr, _amountArr, _includingFees
        );
       
        address signer = preAuthValidations(proof, message, token, r, s, v);

        // Deduct network fee if broadcaster charges network fee
        if (networkFee > 0) {
            privateTransfer(signer, msg.sender, networkFee, true, false);
        }
        // Execute original transfer function

        for(uint256 i = 0; i < _addressArr.length; i++){
            uint256 _value = _amountArr[i];
            address _to = _addressArr[i];
            privateTransfer(signer, _to, _value, false, _includingFees);
        }

        return true;

    }

    /**
     * @notice Delegated transfer. Gas fee will be paid by relayer
     * @param message The message that user signed
     * @param r Signature component
     * @param s Signature component
     * @param v Signature component
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to relayer for gas fee he spends
     * @param to The recipient address
     * @param amount The amount to be transferred
     * @param includingFees Denotes if fee should be deducted from amount or added to amount
     * @return Bool value
     */
    function preAuthorizedTransfer(
        bytes32 message, bytes32 r, bytes32 s, uint8 v, bytes32 token, uint256 networkFee, address to, uint256 amount, bool includingFees)
        public
    {

        bytes32 proof = getProofTransfer(methodWord_transfer, token, networkFee, msg.sender, to, amount, includingFees);
        address signer = preAuthValidations(proof, message, token, r, s, v);

        // Deduct network fee if broadcaster charges network fee
        if (networkFee > 0) {
            privateTransfer(signer, msg.sender, networkFee, true, false);
        }

        privateTransfer(signer, to, amount, false, includingFees);
        
    }

    /**
     * @notice Delegated approval. Gas fee will be paid by relayer
     * @dev Only approve, increaseApproval and decreaseApproval can be delegated
     * @param message The message that user signed
     * @param r Signature component
     * @param s Signature component
     * @param v Signature component
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to relayer for gas fee he spends
     * @param to The spender address
     * @param amount The amount to be allowed
     * @return Bool value
     */
    function preAuthorizedApproval(
        bytes4 methodHash, bytes32 message, bytes32 r, bytes32 s, uint8 v, bytes32 token, uint256 networkFee, address to, uint256 amount)
        public
        returns (bool)
    {
        bytes32 proof = getProofApproval (methodHash, token, networkFee, msg.sender, to, amount);
        address signer = preAuthValidations(proof, message, token, r, s, v);

        // Perform approval
        if(methodHash == methodWord_approve) return _approve(signer, to, amount);
        else if(methodHash == methodWord_increaseApproval) return _increaseApproval(signer, to, amount);
        else if(methodHash == methodWord_decreaseApproval) return _decreaseApproval(signer, to, amount);
    }

    /**
     * @notice Validates the message and signature
     * @param proof The message that was expected to be signed by user
     * @param message The message that user signed
     * @param r Signature component
     * @param s Signature component
     * @param v Signature component
     * @param token The unique token for each delegated function
     * @return address Signer of message
     */
    function preAuthValidations(bytes32 proof, bytes32 message, bytes32 token, bytes32 r, bytes32 s, uint8 v)
        private
        returns(address)
    {
        address signer = getSigner(message, r, s, v);
        require(signer != address(0),"Zero address not allowed");
        require(!tokenUsed[signer][token],"Token already used");
        require(proof == message, "Invalid proof");
        tokenUsed[signer][token] = true;
        return signer;
    }

    
    /**
     * @notice Find signer
     * @param message The message that user signed
     * @param r Signature component
     * @param s Signature component
     * @param v Signature component
     * @return address Signer of message
     */
    function getSigner(bytes32 message, bytes32 r, bytes32 s, uint8 v)
        public
        pure
        returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        address signer = ecrecover(prefixedHash, v, r, s);
        return signer;
    }

    
    /**
     * @notice The message to be signed in case of delegated bulk transfer
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to relayer for gas fee he spends
     * @param _addressArr The array of recipients
     * @param _amountArr The array of amounts to be transferred
     * @param _includingFees Denotes if fee should be deducted from amount or added to amount
     * @return Bool value
     */
    function getProofBulkTransfer(bytes32 token, uint256 networkFee, address broadcaster, address[] memory _addressArr, uint256[] memory _amountArr, bool _includingFees)
        public
        view
        returns (bytes32)
    {
        bytes32 proof = keccak256(abi.encodePacked(
            getChainID(),
            bytes4(methodWord_transfer),
            address(this),
            token,
            networkFee,
            broadcaster,
            _addressArr,
            _amountArr,
            _includingFees
        ));
        return proof;
    }



    /**
     * @notice Get the message to be signed in case of delegated transfer/approvals
     * @param methodHash The method hash for which delegate action in to be performed
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to relayer for gas fee he spends
     * @param to The recipient or spender
     * @param amount The amount to be approved
     * @return Bool value
     */
    function getProofApproval(bytes4 methodHash, bytes32 token, uint256 networkFee, address broadcaster, address to, uint256 amount)
        public
        view
        returns (bytes32)
    {
        require(
            methodHash == methodWord_approve ||
            methodHash == methodWord_increaseApproval ||
            methodHash == methodWord_decreaseApproval,
            "Method not supported");
        bytes32 proof = keccak256(abi.encodePacked(
            getChainID(),
            bytes4(methodHash),
            address(this),
            token,
            networkFee,
            broadcaster,
            to,
            amount
        ));
        return proof;
    }

    /**
     * @notice Get the message to be signed in case of delegated transfer/approvals
     * @param methodHash The method hash for which delegate action in to be performed
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to relayer for gas fee he spends
     * @param to The recipient or spender
     * @param amount The amount to be transferred
     * @param includingFees Denotes if fee should be deducted from amount or added to amount
     * @return Bool value
     */
    function getProofTransfer(bytes4 methodHash, bytes32 token, uint256 networkFee, address broadcaster, address to, uint256 amount, bool includingFees)
        public
        view
        returns (bytes32)
    {
        require(methodHash == methodWord_transfer, "Method not supported");
        bytes32 proof = keccak256(abi.encodePacked(
            getChainID(),
            bytes4(methodHash),
            address(this),
            token,
            networkFee,
            broadcaster,
            to,
            amount,
            includingFees
        ));
        return proof;
    }

   

}