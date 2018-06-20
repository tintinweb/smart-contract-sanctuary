pragma solidity ^0.4.18;

/// @title DepositWalletInterface
///
/// Defines an interface for a wallet that can be deposited/withdrawn by 3rd contract
contract DepositWalletInterface {
    function deposit(address _asset, address _from, uint256 amount) public returns (uint);
    function withdraw(address _asset, address _to, uint256 amount) public returns (uint);
}

/**
 * @title Owned contract with safe ownership pass.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public contractOwner;

    /**
     * Contract owner address
     */
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    /**
    * @dev Owner check modifier
    */
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only owner can call it
     */
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

    /**
     * Prepares ownership pass.
     *
     * Can only be called by current owner.
     *
     * @param _to address of the next owner. 0x0 is not allowed.
     *
     * @return success.
     */
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

    /**
     * Finalize ownership pass.
     *
     * Can only be called by pending owner.
     *
     * @return success.
     */
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    /**
    *  Common result code. Means everything is fine.
    */
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}

contract BaseWallet is Object, DepositWalletInterface {

    uint constant CUSTOMER_WALLET_SCOPE = 60000;
    uint constant CUSTOMER_WALLET_NOT_OK = CUSTOMER_WALLET_SCOPE + 1;

    address public customer;

    modifier onlyCustomer() {
        if (msg.sender != customer) {
            revert();
        }
        _;
    }

    function() public payable {
        revert();
    }

    /// Init contract by setting Emission ProviderWallet address
    /// that can be associated and have an account for this contract
    ///
    /// @dev Allowed only for contract owner
    ///
    /// @param _customer Emission Provider address
    ///
    /// @return  code
    function init(address _customer) public onlyContractOwner returns (uint code) {
        require(_customer != 0x0);
        customer = _customer;
        return OK;
    }

    /// Call `selfdestruct` when contract is not needed anymore. Also takes a list of tokens
    /// that can be associated and have an account for this contract
    ///
    /// @dev Allowed only for contract owner
    ///
    /// @param tokens an array of tokens addresses
    function destroy(address[] tokens) public onlyContractOwner {
        withdrawnTokens(tokens, msg.sender);
        selfdestruct(msg.sender);
    }

    /// @dev Call destroy(address[] tokens) instead
    function destroy() public onlyContractOwner {
        revert();
    }

    /// Deposits some amount of tokens on wallet&#39;s account using ERC20 tokens
    ///
    /// @dev Allowed only for rewards
    ///
    /// @param _asset an address of token
    /// @param _from an address of a sender who is willing to transfer her resources
    /// @param _amount an amount of tokens (resources) a sender wants to transfer
    ///
    /// @return code
    function deposit(address _asset, address _from, uint256 _amount) public onlyCustomer returns (uint) {
        if (!ERC20Interface(_asset).transferFrom(_from, this, _amount)) {
            return CUSTOMER_WALLET_NOT_OK;
        }
        return OK;
    }

    /// Withdraws some amount of tokens from wallet&#39;s account using ERC20 tokens
    ///
    /// @dev Allowed only for rewards
    ///
    /// @param _asset an address of token
    /// @param _to an address of a receiver who is willing to get stored resources
    /// @param _amount an amount of tokens (resources) a receiver wants to get
    ///
    /// @return  code
    function withdraw(address _asset, address _to, uint256 _amount) public onlyCustomer returns (uint) {
        if (!ERC20Interface(_asset).transfer(_to, _amount)) {
            return CUSTOMER_WALLET_NOT_OK;
        }
        return OK;
    }

    /// Approve some amount of tokens from wallet&#39;s account using ERC20 tokens
    ///
    /// @dev Allowed only for rewards
    ///
    /// @param _asset an address of token
    /// @param _to an address of a receiver who is willing to get stored resources
    /// @param _amount an amount of tokens (resources) a receiver wants to get
    ///
    /// @return  code
    function approve(address _asset, address _to, uint256 _amount) public onlyCustomer returns (uint) {
        if (!ERC20Interface(_asset).approve(_to, _amount)) {
            return CUSTOMER_WALLET_NOT_OK;
        }
        return OK;
    }
}

contract ProfiteroleWallet is BaseWallet {
	
}