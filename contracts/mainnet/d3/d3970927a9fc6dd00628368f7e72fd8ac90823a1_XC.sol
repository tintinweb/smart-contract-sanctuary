pragma solidity ^0.4.13;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20 {

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success) {

        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(allowance[_from][msg.sender] >= _value);

        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);

        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     *   ######################
     *  #  private function  #
     * ######################
     */

    function _transfer(address _from, address _to, uint _value) internal {

        require(balanceOf[_from] >= _value);

        require(SafeMath.add(balanceOf[_to], _value) >= balanceOf[_to]);

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);

        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

        emit Transfer(_from, _to, _value);
    }
}

contract Token is ERC20 {

    uint8 public constant decimals = 9;

    uint256 public constant initialSupply = 10 * (10 ** 8) * (10 ** uint256(decimals));

    string public constant name = &#39;INK Coin&#39;;

    string public constant symbol = &#39;INK&#39;;


    function() public {

        revert();
    }

    function Token() public {

        balanceOf[msg.sender] = initialSupply;

        totalSupply = initialSupply;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {

        if (approve(_spender, _value)) {

            if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {

                revert();
            }

            return true;
        }
    }

}

interface XCInterface {

    /**
     * Set contract service status.
     * @param status contract service status (0:closed;1:only-closed-lock;2:only-closed-unlock;3:opened;).
     */
    function setStatus(uint8 status) external;

    /**
     * Get contract service status.
     * @return contract service status.
     */
    function getStatus() external view returns (uint8);

    /**
     * Get the current contract platform name.
     * @return contract platform name.
     */
    function getPlatformName() external view returns (bytes32);

    /**
     * Set the current contract administrator.
     * @param account account of contract administrator.
     */
    function setAdmin(address account) external;

    /**
     * Get the current contract administrator.
     * @return contract administrator.
     */
    function getAdmin() external view returns (address);

    /**
     * Set the Token contract address.
     * @param account contract address.
     */
    function setToken(address account) external;

    /**
     * Get the Token contract address.
     * @return contract address.
     */
    function getToken() external view returns (address);

    /**
     * Set the XCPlugin contract address.
     * @param account contract address.
     */
    function setXCPlugin(address account) external;

    /**
     * Get the XCPlugin contract address.
     * @return contract address.
     */
    function getXCPlugin() external view returns (address);

    /**
     * Set the comparison symbol in the contract.
     * @param symbol comparison symbol ({"-=" : ">" , "+=" : ">=" }).
     */
    function setCompare(bytes2 symbol) external;

    /**
     * Get the comparison symbol in the contract.
     * @return comparison symbol.
     */
    function getCompare() external view returns (bytes2);

    /**
     * Transfer out of cross chain.
     * @param toPlatform name of to platform.
     * @param toAccount account of to platform.
     * @param value transfer amount.
     */
    function lock(bytes32 toPlatform, address toAccount, uint value) external payable;

    /**
     * Transfer in of cross chain.
     * @param txid transaction id.
     * @param fromPlatform name of form platform.
     * @param fromAccount ame of to platform.
     * @param toAccount account of to platform.
     * @param value transfer amount.
     */
    function unlock(string txid, bytes32 fromPlatform, address fromAccount, address toAccount, uint value) external payable;

    /**
     * Transfer the misoperation to the amount of the contract account to the specified account.
     * @param account the specified account.
     * @param value transfer amount.
     */
    function withdraw(address account, uint value) external payable;

    /**
     * Transfer the money(qtum/eth) from the contract account.
     * @param account the specified account.
     * @param value transfer amount.
     */
    function transfer(address account, uint value) external payable;

    /**
     * Deposit money(eth) into a contract.
     */
    function deposit() external payable;
}

contract XC is XCInterface {

    /**
     * Contract Administrator
     * @field status Contract external service status.
     * @field platformName Current contract platform name.
     * @field account Current contract administrator.
     */
    struct Admin {

        uint8 status;

        bytes32 platformName;

        bytes32 tokenSymbol;

        bytes2 compareSymbol;

        address account;
    }

    Admin private admin;

    uint public lockBalance;

    Token private token;

    XCPlugin private xcPlugin;

    event Lock(bytes32 toPlatform, address toAccount, bytes32 value, bytes32 tokenSymbol);

    event Unlock(string txid, bytes32 fromPlatform, address fromAccount, bytes32 value, bytes32 tokenSymbol);

    event Deposit(address from, bytes32 value);

    function XC() public payable {

        init();
    }

    function init() internal {

        // Admin {status | platformName | tokenSymbol | compareSymbol | account}
        admin.status = 3;

        admin.platformName = "ETH";

        admin.tokenSymbol = "INK";

        admin.compareSymbol = "+=";

        admin.account = msg.sender;

        //totalSupply = 10 * (10 ** 8) * (10 ** 9);
        lockBalance = 10 * (10 ** 8) * (10 ** 9);

        token = Token(0xc15d8f30fa3137eee6be111c2933f1624972f45c);

        xcPlugin = XCPlugin(0x55c87c2e26f66fd3642645c3f25c9e81a75ec0f4);
    }

    function setStatus(uint8 status) external {

        require(admin.account == msg.sender);

        require(status == 0 || status == 1 || status == 2 || status == 3);

        if (admin.status != status) {

            admin.status = status;
        }
    }

    function getStatus() external view returns (uint8) {

        return admin.status;
    }

    function getPlatformName() external view returns (bytes32) {

        return admin.platformName;
    }

    function setAdmin(address account) external {

        require(account != address(0));

        require(admin.account == msg.sender);

        if (admin.account != account) {

            admin.account = account;
        }
    }

    function getAdmin() external view returns (address) {

        return admin.account;
    }

    function setToken(address account) external {

        require(admin.account == msg.sender);

        if (token != account) {

            token = Token(account);
        }
    }

    function getToken() external view returns (address) {

        return token;
    }

    function setXCPlugin(address account) external {

        require(admin.account == msg.sender);

        if (xcPlugin != account) {

            xcPlugin = XCPlugin(account);
        }
    }

    function getXCPlugin() external view returns (address) {

        return xcPlugin;
    }

    function setCompare(bytes2 symbol) external {

        require(admin.account == msg.sender);

        require(symbol == "+=" || symbol == "-=");

        if (admin.compareSymbol != symbol) {

            admin.compareSymbol = symbol;
        }
    }

    function getCompare() external view returns (bytes2){

        require(admin.account == msg.sender);

        return admin.compareSymbol;
    }

    function lock(bytes32 toPlatform, address toAccount, uint value) external payable {

        require(admin.status == 2 || admin.status == 3);

        require(xcPlugin.getStatus());

        require(xcPlugin.existPlatform(toPlatform));

        require(toAccount != address(0));

        // require(token.totalSupply >= value && value > 0);
        require(value > 0);

        //get user approve the contract quota
        uint allowance = token.allowance(msg.sender, this);

        require(toCompare(allowance, value));

        //do transferFrom
        bool success = token.transferFrom(msg.sender, this, value);

        require(success);

        //record the amount of local platform turn out
        lockBalance = SafeMath.add(lockBalance, value);
        // require(token.totalSupply >= lockBalance);

        //trigger Lock
        emit Lock(toPlatform, toAccount, bytes32(value), admin.tokenSymbol);
    }

    function unlock(string txid, bytes32 fromPlatform, address fromAccount, address toAccount, uint value) external payable {

        require(admin.status == 1 || admin.status == 3);

        require(xcPlugin.getStatus());

        require(xcPlugin.existPlatform(fromPlatform));

        require(toAccount != address(0));

        // require(token.totalSupply >= value && value > 0);
        require(value > 0);

        //verify args by function xcPlugin.verify
        bool complete;

        bool verify;

        (complete, verify) = xcPlugin.verifyProposal(fromPlatform, fromAccount, toAccount, value, admin.tokenSymbol, txid);

        require(verify && !complete);

        //get contracts balance
        uint balance = token.balanceOf(this);

        //validate the balance of contract were less than amount
        require(toCompare(balance, value));

        require(token.transfer(toAccount, value));

        require(xcPlugin.commitProposal(fromPlatform, txid));

        lockBalance = SafeMath.sub(lockBalance, value);

        emit Unlock(txid, fromPlatform, fromAccount, bytes32(value), admin.tokenSymbol);
    }

    function withdraw(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        // require(token.totalSupply >= value && value > 0);
        require(value > 0);

        uint balance = token.balanceOf(this);

        require(toCompare(SafeMath.sub(balance, lockBalance), value));

        bool success = token.transfer(account, value);

        require(success);
    }

    function transfer(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0 && value >= address(this).balance);

        this.transfer(account, value);
    }

    function deposit() external payable {

        emit Deposit(msg.sender, bytes32(msg.value));
    }

    /**
     *   ######################
     *  #  private function  #
     * ######################
     */

    function toCompare(uint f, uint s) internal view returns (bool) {

        if (admin.compareSymbol == "-=") {

            return f > s;
        } else if (admin.compareSymbol == "+=") {

            return f >= s;
        } else {

            return false;
        }
    }
}

interface XCPluginInterface {

    /**
     * Open the contract service status.
     */
    function start() external;

    /**
     * Close the contract service status.
     */
    function stop() external;

    /**
     * Get contract service status.
     * @return contract service status.
     */
    function getStatus() external view returns (bool);

    /**
     * Get the current contract platform name.
     * @return contract platform name.
     */
    function getPlatformName() external view returns (bytes32);

    /**
     * Set the current contract administrator.
     * @param account account of contract administrator.
     */
    function setAdmin(address account) external;

    /**
     * Get the current contract administrator.
     * @return contract administrator.
     */
    function getAdmin() external view returns (address);

    /**
     * Add a contract trust caller.
     * @param caller account of caller.
     */
    function addCaller(address caller) external;

    /**
     * Delete a contract trust caller.
     * @param caller account of caller.
     */
    function deleteCaller(address caller) external;

    /**
     * Whether the trust caller exists.
     * @param caller account of caller.
     * @return whether exists.
     */
    function existCaller(address caller) external view returns (bool);

    /**
     * Get all contract trusted callers.
     * @return al lcallers.
     */
    function getCallers() external view returns (address[]);

    /**
     * Add a trusted platform name.
     * @param name a platform name.
     */
    function addPlatform(bytes32 name) external;

    /**
     * Delete a trusted platform name.
     * @param name a platform name.
     */
    function deletePlatform(bytes32 name) external;

    /**
     * Whether the trusted platform information exists.
     * @param name a platform name.
     * @return whether exists.
     */
    function existPlatform(bytes32 name) external view returns (bool);

    /**
     * Add the trusted platform public key information.
     * @param platformName a platform name.
     * @param publicKey a public key.
     */
    function addPublicKey(bytes32 platformName, address publicKey) external;

    /**
     * Delete the trusted platform public key information.
     * @param platformName a platform name.
     * @param publicKey a public key.
     */
    function deletePublicKey(bytes32 platformName, address publicKey) external;

    /**
     * Whether the trusted platform public key information exists.
     * @param platformName a platform name.
     * @param publicKey a public key.
     */
    function existPublicKey(bytes32 platformName, address publicKey) external view returns (bool);

    /**
     * Get the count of public key for the trusted platform.
     * @param platformName a platform name.
     * @return count of public key.
     */
    function countOfPublicKey(bytes32 platformName) external view returns (uint);

    /**
     * Get the list of public key for the trusted platform.
     * @param platformName a platform name.
     * @return list of public key.
     */
    function publicKeys(bytes32 platformName) external view returns (address[]);

    /**
     * Set the weight of a trusted platform.
     * @param platformName a platform name.
     * @param weight weight of platform.
     */
    function setWeight(bytes32 platformName, uint weight) external;

    /**
     * Get the weight of a trusted platform.
     * @param platformName a platform name.
     * @return weight of platform.
     */
    function getWeight(bytes32 platformName) external view returns (uint);

    /**
     * Initiate and vote on the transaction proposal.
     * @param fromPlatform name of form platform.
     * @param fromAccount name of to platform.
     * @param toAccount account of to platform.
     * @param value transfer amount.
     * @param tokenSymbol token Symbol.
     * @param txid transaction id.
     * @param sig transaction signature.
     */
    function voteProposal(bytes32 fromPlatform, address fromAccount, address toAccount, uint value, bytes32 tokenSymbol, string txid, bytes sig) external;

    /**
     * Verify that the transaction proposal is valid.
     * @param fromPlatform name of form platform.
     * @param fromAccount name of to platform.
     * @param toAccount account of to platform.
     * @param value transfer amount.
     * @param tokenSymbol token Symbol.
     * @param txid transaction id.
     */
    function verifyProposal(bytes32 fromPlatform, address fromAccount, address toAccount, uint value, bytes32 tokenSymbol, string txid) external view returns (bool, bool);

    /**
     * Commit the transaction proposal.
     * @param platformName a platform name.
     * @param txid transaction id.
     */
    function commitProposal(bytes32 platformName, string txid) external returns (bool);

    /**
     * Get the transaction proposal information.
     * @param platformName a platform name.
     * @param txid transaction id.
     * @return status completion status of proposal.
     * @return fromAccount account of to platform.
     * @return toAccount account of to platform.
     * @return value transfer amount.
     * @return voters notarial voters.
     * @return weight The weight value of the completed time.
     */
    function getProposal(bytes32 platformName, string txid) external view returns (bool status, address fromAccount, address toAccount, uint value, address[] voters, uint weight);

    /**
     * Delete the transaction proposal information.
     * @param platformName a platform name.
     * @param txid transaction id.
     */
    function deleteProposal(bytes32 platformName, string txid) external;

    /**
     * Transfer the money(qtum/eth) from the contract account.
     * @param account the specified account.
     * @param value transfer amount.
     */
    function transfer(address account, uint value) external payable;
}

contract XCPlugin is XCPluginInterface {

    /**
     * Contract Administrator
     * @field status Contract external service status.
     * @field platformName Current contract platform name.
     * @field tokenSymbol token Symbol.
     * @field account Current contract administrator.
     */
    struct Admin {

        bool status;

        bytes32 platformName;

        bytes32 tokenSymbol;

        address account;
    }

    /**
     * Transaction Proposal
     * @field status Transaction proposal status(false:pending,true:complete).
     * @field fromAccount Account of form platform.
     * @field toAccount Account of to platform.
     * @field value Transfer amount.
     * @field tokenSymbol token Symbol.
     * @field voters Proposers.
     * @field weight The weight value of the completed time.
     */
    struct Proposal {

        bool status;

        address fromAccount;

        address toAccount;

        uint value;

        bytes32 tokenSymbol;

        address[] voters;

        uint weight;
    }

    /**
     * Trusted Platform
     * @field status Trusted platform state(false:no trusted,true:trusted).
     * @field weight weight of platform.
     * @field publicKeys list of public key.
     * @field proposals list of proposal.
     */
    struct Platform {

        bool status;

        uint weight;

        address[] publicKeys;

        mapping(string => Proposal) proposals;
    }

    Admin private admin;

    address[] private callers;

    mapping(bytes32 => Platform) private platforms;

    function XCPlugin() public {

        init();
    }

    function init() internal {
        // Admin { status | platformName | tokenSymbol | account}
        admin.status = true;

        admin.platformName = "ETH";

        admin.tokenSymbol = "INK";

        admin.account = msg.sender;

        bytes32 platformName = "INK";

        platforms[platformName].status = true;

        platforms[platformName].weight = 1;

        platforms[platformName].publicKeys.push(0x4230a12f5b0693dd88bb35c79d7e56a68614b199);

        platforms[platformName].publicKeys.push(0x07caf88941eafcaaa3370657fccc261acb75dfba);
    }

    function start() external {

        require(admin.account == msg.sender);

        if (!admin.status) {

            admin.status = true;
        }
    }

    function stop() external {

        require(admin.account == msg.sender);

        if (admin.status) {

            admin.status = false;
        }
    }

    function getStatus() external view returns (bool) {

        return admin.status;
    }

    function getPlatformName() external view returns (bytes32) {

        return admin.platformName;
    }

    function setAdmin(address account) external {

        require(account != address(0));

        require(admin.account == msg.sender);

        if (admin.account != account) {

            admin.account = account;
        }
    }

    function getAdmin() external view returns (address) {

        return admin.account;
    }

    function addCaller(address caller) external {

        require(admin.account == msg.sender);

        if (!_existCaller(caller)) {

            callers.push(caller);
        }
    }

    function deleteCaller(address caller) external {

        require(admin.account == msg.sender);

        if (_existCaller(caller)) {

            bool exist;

            for (uint i = 0; i <= callers.length; i++) {

                if (exist) {

                    if (i == callers.length) {

                        delete callers[i - 1];

                        callers.length--;
                    } else {

                        callers[i - 1] = callers[i];
                    }
                } else if (callers[i] == caller) {

                    exist = true;
                }
            }

        }
    }

    function existCaller(address caller) external view returns (bool) {

        return _existCaller(caller);
    }

    function getCallers() external view returns (address[]) {

        require(admin.account == msg.sender);

        return callers;
    }

    function addPlatform(bytes32 name) external {

        require(admin.account == msg.sender);

        require(name != "");

        require(name != admin.platformName);

        if (!_existPlatform(name)) {

            platforms[name].status = true;

            if (platforms[name].weight == 0) {

                platforms[name].weight = 1;
            }
        }
    }

    function deletePlatform(bytes32 name) external {

        require(admin.account == msg.sender);

        require(name != admin.platformName);

        if (_existPlatform(name)) {

            platforms[name].status = false;
        }
    }

    function existPlatform(bytes32 name) external view returns (bool){

        return _existPlatform(name);
    }

    function setWeight(bytes32 platformName, uint weight) external {

        require(admin.account == msg.sender);

        require(_existPlatform(platformName));

        require(weight > 0);

        if (platforms[platformName].weight != weight) {

            platforms[platformName].weight = weight;
        }
    }

    function getWeight(bytes32 platformName) external view returns (uint) {

        require(admin.account == msg.sender);

        require(_existPlatform(platformName));

        return platforms[platformName].weight;
    }

    function addPublicKey(bytes32 platformName, address publicKey) external {

        require(admin.account == msg.sender);

        require(_existPlatform(platformName));

        require(publicKey != address(0));

        address[] storage listOfPublicKey = platforms[platformName].publicKeys;

        for (uint i; i < listOfPublicKey.length; i++) {

            if (publicKey == listOfPublicKey[i]) {

                return;
            }
        }

        listOfPublicKey.push(publicKey);
    }

    function deletePublicKey(bytes32 platformName, address publickey) external {

        require(admin.account == msg.sender);

        require(_existPlatform(platformName));

        address[] storage listOfPublicKey = platforms[platformName].publicKeys;

        bool exist;

        for (uint i = 0; i <= listOfPublicKey.length; i++) {

            if (exist) {
                if (i == listOfPublicKey.length) {

                    delete listOfPublicKey[i - 1];

                    listOfPublicKey.length--;
                } else {

                    listOfPublicKey[i - 1] = listOfPublicKey[i];
                }
            } else if (listOfPublicKey[i] == publickey) {

                exist = true;
            }
        }
    }

    function existPublicKey(bytes32 platformName, address publicKey) external view returns (bool) {

        require(admin.account == msg.sender);

        return _existPublicKey(platformName, publicKey);
    }

    function countOfPublicKey(bytes32 platformName) external view returns (uint){

        require(admin.account == msg.sender);

        require(_existPlatform(platformName));

        return platforms[platformName].publicKeys.length;
    }

    function publicKeys(bytes32 platformName) external view returns (address[]){

        require(admin.account == msg.sender);

        require(_existPlatform(platformName));

        return platforms[platformName].publicKeys;
    }

    function voteProposal(bytes32 fromPlatform, address fromAccount, address toAccount, uint value, bytes32 tokenSymbol, string txid, bytes sig) external {

        require(admin.status);

        require(_existPlatform(fromPlatform));

        bytes32 msgHash = hashMsg(fromPlatform, fromAccount, admin.platformName, toAccount, value, tokenSymbol, txid);

        // address publicKey = ecrecover(msgHash, v, r, s);
        address publicKey = recover(msgHash, sig);

        require(_existPublicKey(fromPlatform, publicKey));

        Proposal storage proposal = platforms[fromPlatform].proposals[txid];

        if (proposal.value == 0) {

            proposal.fromAccount = fromAccount;

            proposal.toAccount = toAccount;

            proposal.value = value;

            proposal.tokenSymbol = tokenSymbol;
        } else {

            require(proposal.fromAccount == fromAccount && proposal.toAccount == toAccount && proposal.value == value && proposal.tokenSymbol == tokenSymbol);
        }

        changeVoters(fromPlatform, publicKey, txid);
    }

    function verifyProposal(bytes32 fromPlatform, address fromAccount, address toAccount, uint value, bytes32 tokenSymbol, string txid) external view returns (bool, bool) {

        require(admin.status);

        require(_existPlatform(fromPlatform));

        Proposal storage proposal = platforms[fromPlatform].proposals[txid];

        if (proposal.status) {

            return (true, (proposal.voters.length >= proposal.weight));
        }

        if (proposal.value == 0) {

            return (false, false);
        }

        require(proposal.fromAccount == fromAccount && proposal.toAccount == toAccount && proposal.value == value && proposal.tokenSymbol == tokenSymbol);

        return (false, (proposal.voters.length >= platforms[fromPlatform].weight));
    }

    function commitProposal(bytes32 platformName, string txid) external returns (bool) {

        require(admin.status);

        require(_existCaller(msg.sender) || msg.sender == admin.account);

        require(_existPlatform(platformName));

        require(!platforms[platformName].proposals[txid].status);

        platforms[platformName].proposals[txid].status = true;

        platforms[platformName].proposals[txid].weight = platforms[platformName].proposals[txid].voters.length;

        return true;
    }

    function getProposal(bytes32 platformName, string txid) external view returns (bool status, address fromAccount, address toAccount, uint value, address[] voters, uint weight){

        require(admin.status);

        require(_existPlatform(platformName));

        fromAccount = platforms[platformName].proposals[txid].fromAccount;

        toAccount = platforms[platformName].proposals[txid].toAccount;

        value = platforms[platformName].proposals[txid].value;

        voters = platforms[platformName].proposals[txid].voters;

        status = platforms[platformName].proposals[txid].status;

        weight = platforms[platformName].proposals[txid].weight;

        return;
    }

    function deleteProposal(bytes32 platformName, string txid) external {

        require(msg.sender == admin.account);

        require(_existPlatform(platformName));

        delete platforms[platformName].proposals[txid];
    }

    function transfer(address account, uint value) external payable {

        require(admin.account == msg.sender);

        require(account != address(0));

        require(value > 0 && value >= address(this).balance);

        this.transfer(account, value);
    }

    /**
     *   ######################
     *  #  private function  #
     * ######################
     */

    function hashMsg(bytes32 fromPlatform, address fromAccount, bytes32 toPlatform, address toAccount, uint value, bytes32 tokenSymbol, string txid) internal pure returns (bytes32) {

        return sha256(bytes32ToStr(fromPlatform), ":0x", uintToStr(uint160(fromAccount), 16), ":", bytes32ToStr(toPlatform), ":0x", uintToStr(uint160(toAccount), 16), ":", uintToStr(value, 10), ":", bytes32ToStr(tokenSymbol), ":", txid);
    }

    function changeVoters(bytes32 platformName, address publicKey, string txid) internal {

        address[] storage voters = platforms[platformName].proposals[txid].voters;

        bool change = true;

        for (uint i = 0; i < voters.length; i++) {

            if (voters[i] == publicKey) {

                change = false;
            }
        }

        if (change) {

            voters.push(publicKey);
        }
    }

    function bytes32ToStr(bytes32 b) internal pure returns (string) {

        uint length = b.length;

        for (uint i = 0; i < b.length; i++) {

            if (b[b.length - 1 - i] == "") {

                length -= 1;
            } else {

                break;
            }
        }

        bytes memory bs = new bytes(length);

        for (uint j = 0; j < length; j++) {

            bs[j] = b[j];
        }

        return string(bs);
    }

    function uintToStr(uint value, uint base) internal pure returns (string) {

        uint _value = value;

        uint length = 0;

        bytes16 tenStr = "0123456789abcdef";

        while (true) {

            if (_value > 0) {

                length ++;

                _value = _value / base;
            } else {

                break;
            }
        }

        if (base == 16) {
            length = 40;
        }

        bytes memory bs = new bytes(length);

        for (uint i = 0; i < length; i++) {

            bs[length - 1 - i] = tenStr[value % base];

            value = value / base;
        }

        return string(bs);
    }

    function _existCaller(address caller) internal view returns (bool) {

        for (uint i = 0; i < callers.length; i++) {

            if (callers[i] == caller) {

                return true;
            }
        }

        return false;
    }

    function _existPlatform(bytes32 name) internal view returns (bool){

        return platforms[name].status;
    }

    function _existPublicKey(bytes32 platformName, address publicKey) internal view returns (bool) {


        address[] memory listOfPublicKey = platforms[platformName].publicKeys;

        for (uint i = 0; i < listOfPublicKey.length; i++) {

            if (listOfPublicKey[i] == publicKey) {

                return true;
            }
        }

        return false;
    }

    function recover(bytes32 hash, bytes sig) internal pure returns (address) {

        bytes32 r;

        bytes32 s;

        uint8 v;

        assembly {

            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {

            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }
}