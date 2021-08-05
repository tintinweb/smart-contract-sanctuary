/**
 *Submitted for verification at Etherscan.io on 2021-01-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract JasmyHyperDrop
{
    address private admin;
    address private signOwner;
    IERC20 private token;
    
    uint256 private defaultTokensAmount;
    uint32 private claimedCount;
    
    mapping(uint16 => uint256) private bitmask;
    
    string private constant ERR_MSG_SENDER = "ERR_MSG_SENDER";
    string private constant ERR_AMOUNT = "ERR_AMOUNT";
    
    //--------------------------------------------------------------------------------------------------------------------------
    constructor(address _admin, address _signOwner, address _tokenAddress, uint256 _defaultTokensAmount) public
    {
        admin                   = _admin;
        signOwner               = _signOwner;
        token                   = IERC20(_tokenAddress);
        defaultTokensAmount     = _defaultTokensAmount;
        
        setClaimed(type(uint16).max, type(uint8).max); // gas savings for the first user that will claim tokens
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function getAdmin() external view returns (address)
    {
        return admin;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function getSignOwner() external view returns (address)
    {
        return signOwner;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function setSignOwner(address _signOwner) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        signOwner = _signOwner;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function getTokenAddress() external view returns (address)
    {
        return address(token);
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function getTotalTokensBalance() external view returns (uint256)
    {
        return token.balanceOf(address(this));
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function sendTokens(address _to, uint256 _amount) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        require(_amount <= token.balanceOf(address(this)), ERR_AMOUNT);
        
        if(_amount == 0)
        {
            token.transfer(_to, token.balanceOf(address(this)));
        }
        else
        {
            token.transfer(_to, _amount);
        }
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function getDefaultTokensAmount() external view returns (uint256)
    {
        return defaultTokensAmount;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function setDefaultTokensAmount(uint256 _amount) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        defaultTokensAmount = _amount;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function getClaimedCount() external view returns (uint32)
    {
        return claimedCount;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function claimTokens(uint16 _block, uint8 _bit, bytes memory _signature) external
    {
        require(!isClaimed(_block, _bit), "ERR_ALREADY_CLAIMED");
        
        string memory message = string(abi.encodePacked(toAsciiString(msg.sender), ";", uintToString(_block), ";", uintToString(_bit)));
        verify(message, _signature);
        
        token.transfer(msg.sender, defaultTokensAmount);
        
        setClaimed(_block, _bit);
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function claimTokens(uint16 _block, uint8 _bit, uint256 _tokensCount, bytes memory _signature) external
    {
        require(!isClaimed(_block, _bit));
        
        string memory message = string(abi.encodePacked(toAsciiString(msg.sender), ";", uintToString(_block), ";", uintToString(_bit), ";", uintToString(_tokensCount)));
        verify(message, _signature);
        
        token.transfer(msg.sender, _tokensCount);
        
        setClaimed(_block, _bit);
    }

    //--------------------------------------------------------------------------------------------------------------------------
    function setClaimed(uint16 _block, uint8 _bit) private
    {
        uint256 bitBlock = bitmask[_block];
        uint256 mask = uint256(1) << _bit;
        
        bitmask[_block] = (bitBlock | mask);
        
        ++claimedCount;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function isClaimed(uint16 _block, uint8 _bit) public view returns (bool)
    {
        uint256 bitBlock = bitmask[_block];
        uint256 mask = uint256(1) << _bit;
        
        return (bitBlock & mask) > 0;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function verify(string memory _message, bytes memory _sig) private view
    {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_message))));
        address messageSigner = recover(messageHash, _sig);
        
        require(messageSigner == signOwner, "ERR_VERIFICATION_FAILED");
    }

    //--------------------------------------------------------------------------------------------------------------------------
    function recover(bytes32 _hash, bytes memory _sig) private pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        require(_sig.length == 65, "ERR_RECOVER_SIG_SIZE");

        assembly
        {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        if(v < 27)
        {
            v += 27;
        }
        
        require(v == 27 || v == 28, "ERR_RECOVER_INVALID_SIG");

        return ecrecover(_hash, v, r, s);
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function uintToString(uint _i) private pure returns (string memory)
    {
        if(_i == 0)
        {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0)
        {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while(_i != 0)
        {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function toAsciiString(address _addr) private pure returns (string memory)
    {
        bytes memory s = new bytes(40);
        for(uint i = 0; i < 20; i++)
        {
            byte b = byte(uint8(uint(_addr) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    //--------------------------------------------------------------------------------------------------------------------------
    function char(byte value) private pure returns (byte)
    {
        if(uint8(value) < 10)
        {
            return byte(uint8(value) + 0x30);
        }
        else
        {
            return byte(uint8(value) + 0x57);
        }
    }
}