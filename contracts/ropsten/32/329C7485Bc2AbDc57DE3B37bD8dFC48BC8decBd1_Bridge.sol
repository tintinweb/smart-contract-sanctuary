pragma solidity 0.7.5;

import "./IERC20.sol";
import './IBridge.sol';
import './TokenPool.sol';
import './Authorizable.sol';


/**
* @dev Change to external token pool if block gas limit becomes an issue
* @dev Bridge implements IBridge interface to mint and burn transactions
*/

contract Bridge is IBridge, TokenPool, Authorizable {

    uint256 private burnNonce = 0;
    mapping (uint256 => bool) nonceMinted;

    /**
    * @dev Initializes the contract, sets {token} {authorizers} and 
    * initializes authorizers and token pool. 
    */
    constructor(IERC20 _token, IAuthorizers _authorizers) TokenPool(_token) Authorizable(_authorizers) {

    }

    /**
    * @dev see {IBridge-burn}
    */
    function burn(uint256 _amount, bytes calldata _clientId)
        external
        override
    {
        _burn(msg.sender, _amount, _clientId);
    }

    /**
    * @dev Implementation of the burn function
    * @param _from - the address to burn tokens from
    * @param _amount - The amount of tokens to burn
    * @param _clientId - The 0chain client ID of the burner
    */
    function _burn(address _from, uint256 _amount, bytes memory _clientId)
        private
    {
        require(this.token().transferFrom(_from, address(this), _amount),
               'Bridge: transfer into burn pool failed');
        // first nonce is 1 not 0
        burnNonce = burnNonce + 1;
        emit Burned(_from, _amount, _clientId, burnNonce);

    }

    /**
    * @dev see {Ibridge-mint}
    */
    function mint(uint256 _amount, bytes calldata _txid, uint256 _nonce, bytes calldata signatures)
        external
        override
    {
        require(!nonceMinted[_nonce], "Nonce already used");
        bytes32 message = authorizers().message(msg.sender, _amount, _txid, _nonce);
        _mint(msg.sender, _amount, _txid, _nonce, message, signatures);
    }
    /**
    * @dev implements third party mint execution
    */
    function mintFor(address _for, uint256 _amount, bytes calldata _txid, uint256 _nonce, bytes calldata signatures)
        external
    {
        require(!nonceMinted[_nonce], "Nonce already used");
        bytes32 message = authorizers().message(_for, _amount, _txid, _nonce);
        _mint(_for, _amount, _txid, _nonce, message, signatures);
    }
    /**
    * @dev Implementation of the mint function
    * @param _to - The address to mint the tokens to
    * @param _amount - The amount of tokens to mint
    * @param _txid - The txid of the burn transaction on the 0chain
    * @param _nonce - The nonce used to sign the message
    * @param message - The message generated and signed by authorizers
    * @param signatures - The validated signatures concatinated
    */

    function _mint(address _to, uint256 _amount, bytes memory _txid, uint256 _nonce, bytes32 message, bytes calldata signatures) 
        isAuthorized(message, signatures)
        private
    {
        //Authorizer logic
        require(this.token().transfer(_to, _amount),
               'Bridge: transfer out of pool failed');
        nonceMinted[_nonce] = true;
        emit Minted(_to, _amount, _txid, _nonce);
    }
    // TODO UPDATE THIS

    function isAuthorizationValid(uint256 _amount, bytes calldata _txid, uint256 _nonce, bytes calldata signature)
        external
        returns (bool)
    {
        bytes32 message = authorizers().message(msg.sender, _amount, _txid, _nonce);
        return validAuthorization(message, signature);
    }
    function validAuthorization(bytes32 message, bytes calldata signatures)
        internal
        isAuthorized(message, signatures)
        returns (bool)
    {
        return true;
    }
    
}