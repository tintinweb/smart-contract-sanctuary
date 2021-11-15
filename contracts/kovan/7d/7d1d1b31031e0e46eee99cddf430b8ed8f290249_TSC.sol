pragma solidity ^0.6.0;

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only available for owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './Owned.sol';
import './TerminateContractTemplate.sol';
import './interface/IERC20.sol';
import './interface/IExecute.sol';

contract TSC is TerminateContractTemplate {
    
    struct DepositERC20 {
        address tokens;
        uint256 value;
        string description;
        uint256 deposited;
    }

    struct TransferERC20 {
        address receiver;
        address tokens;
        uint256 value;
        string description;
        bool transfered;
    }

    struct DepositETH {
        uint256 value;
        string description;
        uint256 deposited;
    }

    struct TransferETH {
        address payable receiver;
        uint256 value;
        string description;
        bool transfered;
    }

    struct UploadSignature {
        address signer;
        bytes32 source; // sha256 of document
        string description;
        bytes signature;
    }

    struct ListDepositERC20 {
        mapping(uint256 => DepositERC20) list;
        uint256 size;
    }

    struct ListTransferERC20 {
        mapping(uint256 => TransferERC20) list;
        uint256 size;
    }

    struct ListDepositETH {
        mapping(uint256 => DepositETH) list;
        uint256 size;
    }

    struct ListTransferETH {
        mapping(uint256 => TransferETH) list;
        uint256 size;
    }

    struct ListUploadSignature {
        mapping(uint256 => UploadSignature) list;
        uint256 size;
    }

    struct DepositERC20Input {
        address tokens;
        uint256 value;
        string description;
    }

    struct TransferERC20Input {
        address receiver;
        address tokens;
        uint256 value;
        string description;
    }

    struct DepositETHInput {
        uint256 value;
        string description;
    }

    struct TransferETHInput {
        address payable receiver;
        uint256 value;
        string description;
    }

    struct UploadSignatureInput {
        address signer;
        bytes32 source; // sha256 of document
        string description;
    }

    struct BasicInfoInput {
        string title;
        uint256 timeout;
        uint256 deadline;
        
        address tokens_address_start;
        uint256 tokens_amount_start;
            
        address payable partner;
        string description;
        address payable execute_contract;
            
        address rewardToken;
        uint256 rewardValue;
    }

    struct Reward {
        address tokens;
        uint256 value;
    }

    struct StartTimingRequired {
        address tokens;
        uint256 value;
    }
    string public title;

    address payable public partner;
    
    uint256 public timeout;
    
    address payable public execute_contract;
    
    StartTimingRequired public startTimmingRequired;
    Reward public reward;
    
    ListDepositERC20 private listDepositERC20;
    ListTransferERC20 private listTransferERC20;
    ListDepositETH private listDepositETH;
    ListTransferETH private listTransferETH;
    ListUploadSignature private listUploadSignature;
    
    bool public ready;
    bool public isStartTimming;
    
    string public description;
    
    uint256 passCount;

    event StartContract(uint256 timestamp);
    event StartTiming(uint256 timestamp);
    event SignatureUploaded(uint256 indexed _index, bytes32 _source, address _signers, bytes _signature ,uint256 _timestamp);
    event DepositEthCompleted(uint256 indexed _index, uint256 _value, uint256 _timestamp);
    event DepositErc20Completed(uint256 indexed _index, address _tokens, uint256 _value, uint256 _timestamp);
    event TransferEthCompleted(uint256 indexed _index, address _receiver, uint256 _value, uint256 _timestamp);
    event TransferErc20Completed(uint256 indexed _index, address _receiver, address _tokens, uint256 _value, uint256 _timestamp);
    event ContractClosed(uint256 _timestamp, bool completed);
    
    modifier onlyPartner() {
        require(msg.sender == partner, "TSC: Only partner");
        _;
    }
    
    modifier onlyNotReady() {
        require(!ready, "TSC: Contract readied");
        _;
    }
    
    modifier onlyStartTimming() {
        require(isStartTimming, "TSC: Required start timming");
        _;
    }
    
    function setExecuteContract(address payable _address) public onlyOwner onlyNotReady isLive {
        execute_contract = _address;
    }

    function setupAndStart(
        BasicInfoInput memory basicInfo,
        DepositERC20Input[] memory _depositErc20s,
        TransferERC20Input[] memory _transferErc20s,
        DepositETHInput[] memory _depositEths,
        TransferETHInput[] memory _transferEths,
        UploadSignatureInput[] memory _uploadSignatures
    ) public payable onlyOwner onlyNotReady isLive {
        setupBasic(basicInfo);
        setupFunctions(
            _depositErc20s,
            _transferErc20s,
            _depositEths,
            _transferEths,
            _uploadSignatures
        );
        start();
    }
    
    function setupFunctions(
        DepositERC20Input[] memory _depositErc20s,
        TransferERC20Input[] memory _transferErc20s,
        DepositETHInput[] memory _depositEths,
        TransferETHInput[] memory _transferEths,
        UploadSignatureInput[] memory _uploadSignatures
    ) public onlyOwner onlyNotReady isLive {
        _setUpDepositErc20Functions(_depositErc20s);
        _setupTransferErc20Functions(_transferErc20s);
        _setupDepositEthFunctions(_depositEths);
        _setupTransferEthFunctions(_transferEths);
        _setupUploadSignatureFunctions(_uploadSignatures);
    }
    
    
    function setupBasic (
        BasicInfoInput memory basicInfo
    ) public onlyOwner onlyNotReady isLive returns(bool) {
        _setupBasic(
            basicInfo.title, 
            basicInfo.timeout, 
            basicInfo.deadline, 
            basicInfo.tokens_address_start, 
            basicInfo.tokens_amount_start, 
            basicInfo.partner, 
            basicInfo.description, 
            basicInfo.execute_contract, 
            basicInfo.rewardToken, 
            basicInfo.rewardValue
        );
    }
    
    
    function _setupBasic (
        string memory _title,
        uint256 _timeout,
        uint256 _deadline,
    
        address _tokens_address_start, 
        uint256 _tokens_amount_start,
        
        address payable _partner, 
        string memory _description, 
        address payable _execute_contract,
        
        address _rewardToken,
        uint256 _rewardValue
    ) private returns(bool) {
        title = _title;
        partner = _partner;
        description = _description;
        execute_contract = _execute_contract;
        
        timeout = _timeout;
        expiration = _deadline;
        startTimmingRequired = StartTimingRequired({ tokens: _tokens_address_start, value: _tokens_amount_start });
        reward = Reward({ tokens: _rewardToken, value: _rewardValue });
        return true;
    }
    
    function _setUpDepositErc20Functions(DepositERC20Input[] memory _depositErc20s) private returns(bool)  {
        for(uint256 i = 0; i < _depositErc20s.length; i++) {
            DepositERC20Input memory depositErc20 = _depositErc20s[i];
            require(depositErc20.tokens != address(0x0), "TSC: ERC20 tokens address in Deposit ERC20 Function is required different 0x0");
            require(depositErc20.value > 0, "TSC: value of ERC20 in Deposit ERC20 Function is required greater than 0");
            listDepositERC20.list[i] = DepositERC20(depositErc20.tokens, depositErc20.value, depositErc20.description, 0);
        }
        listDepositERC20.size = _depositErc20s.length;
        return true;
    }

    function _setupTransferErc20Functions(TransferERC20Input[] memory _transferErc20s) private returns(bool) {
        for(uint256 i = 0; i < _transferErc20s.length; i++) {
            TransferERC20Input memory transferErc20 = _transferErc20s[i];
            require(transferErc20.receiver != address(0x0), "TSC: receiver in  in Transfer Erc20 Function is required different 0x0");
            require(transferErc20.tokens != address(0x0), "TSC: ERC20 tokens address in Transfer ERC20 Function is required different 0x0");
            require(transferErc20.value > 0, "TSC: value of ETH in Transfer Erc20 Function is required greater than 0");
            listTransferERC20.list[i] = TransferERC20(transferErc20.receiver, transferErc20.tokens, transferErc20.value, transferErc20.description, false);
        }
        listTransferERC20.size = _transferErc20s.length;
        return true;
    }
    
    function _setupDepositEthFunctions(DepositETHInput[] memory _depositEths) private returns(bool) {
        for(uint256 i = 0; i < _depositEths.length; i++) {
            DepositETHInput memory deposit = _depositEths[i];
            require(deposit.value > 0, "TSC: value of ETH in Deposit ETH Function is required greater than 0");
            listDepositETH.list[i] = DepositETH(deposit.value, deposit.description, 0);
        }
        listDepositETH.size = _depositEths.length;
        return true;
    }
    
    function _setupTransferEthFunctions(TransferETHInput[] memory _transferEths) private returns(bool) {
        for(uint256 i = 0; i < _transferEths.length; i++) {
            TransferETHInput memory transferEth = _transferEths[i];
            require(transferEth.receiver != address(0x0), "TSC: receiver in  in Transfer ETH Function is required different 0x0");
            require(transferEth.value > 0, "TSC: value of ETH in Transfer ETH Function is required greater than 0");
            listTransferETH.list[i] = TransferETH(transferEth.receiver, transferEth.value, transferEth.description, false);
        }
        listTransferETH.size = _transferEths.length;
        return true;
    }
    
    function _setupUploadSignatureFunctions(UploadSignatureInput[] memory _uploadSignatures) private returns(bool) {
        for(uint256 i = 0; i < _uploadSignatures.length; i++) {
            UploadSignatureInput memory signature = _uploadSignatures[i];
            require(signature.signer != address(0x0), "TSC: signer in  in Upload Signature Function is required different 0x0");
            listUploadSignature.list[i] = UploadSignature(signature.signer, signature.source, signature.description, "");
        }
        listUploadSignature.size = _uploadSignatures.length;
        return true;
    }
    
    function start() public payable onlyOwner onlyNotReady isLive {
        require(startTimmingRequired.tokens != address(0x0), "TSC: Please setup ERC20 address to start");
        require(timeout > 0, "TSC: Please setup time out");
        if (reward.tokens != address(0x0)) {
            require(IERC20(reward.tokens).transferFrom(msg.sender, address(this), reward.value), "TSC: Please approve reward token");
        } else {
            require(msg.value >= reward.value, "TSC: Please add ETH reward");
        }
        ready = true;
        emit StartContract(block.timestamp);
    }
    
    function startTimming() public onlyPartner isLive {
        require(!isStartTimming, "TSC: Timming started");
        require(IERC20(startTimmingRequired.tokens).transferFrom(msg.sender, address(this), startTimmingRequired.value), "TSC: Please approve transfer tokens for this contract");
        
        if (expiration > block.timestamp + timeout) {
            expiration = block.timestamp + timeout;
        }
        isStartTimming = true;
        emit StartTiming(block.timestamp);
    }
    
    receive() external payable onlyPartner isLive onlyStartTimming {
        uint256 total = msg.value;
        uint256 i = 0; 
        while (total > 0 && i < listDepositETH.size) {
            if (listDepositETH.list[i].deposited < listDepositETH.list[i].value) {
                uint256 remain = listDepositETH.list[i].value - listDepositETH.list[i].deposited;
                if (total > remain) {
                    total -= remain;
                    listDepositETH.list[i].deposited = listDepositETH.list[i].value;
                    passCount++;
                    emit DepositEthCompleted(i, listDepositETH.list[i].deposited, block.timestamp);
                } else {
                    total = 0;
                    listDepositETH.list[i].deposited += total;
                }
            }
            i++;
        }
    }
    
    function close() public isOver {
        uint256 totalFunction = 
            listDepositETH.size + listTransferETH.size + 
            listDepositERC20.size + listTransferERC20.size +
            listUploadSignature.size;

        bool completed = totalFunction == passCount;
        emit ContractClosed(block.timestamp, completed);
        if (execute_contract != address(0)) {
            if (reward.tokens != address(0x0) && reward.value > 0) {
                    IERC20(reward.tokens).transfer(execute_contract, reward.value);
            }
            if (startTimmingRequired.tokens != address(0x0) && startTimmingRequired.value > 0) {
                IERC20(startTimmingRequired.tokens).transfer(execute_contract, startTimmingRequired.value);
            }
            for (uint256 i = 0; i < listDepositERC20.size; i++) {
                if (listDepositERC20.list[i].tokens != address(0x0) && listDepositERC20.list[i].value > 0) {
                    IERC20(listDepositERC20.list[i].tokens).transfer(execute_contract, listDepositERC20.list[i].value);
                }
            }
            execute_contract.transfer(address(this).balance);
            if (completed) {
                IExecute(execute_contract).execute();
            } else {
                IExecute(execute_contract).revert();
            }
        } else {
            if (completed) {
                _closeCompleted();
            } else {
                _closeNotCompleted();
            }
        }
        if (completed) {
            selfdestruct(address(uint160(address(owner))));   
        } else {
            selfdestruct(partner);   
        }
    }
    
    function _closeCompleted() private {
        if (reward.tokens != address(0x0) && reward.value > 0) {
            IERC20(reward.tokens).transfer(partner, reward.value);
        }
        if (reward.tokens == address(0x0) && reward.value > 0) {
            partner.transfer(reward.value);
        }
        if (startTimmingRequired.tokens != address(0x0) && startTimmingRequired.value > 0) {
            IERC20(startTimmingRequired.tokens).transfer(partner, startTimmingRequired.value);
        }
        
        for (uint256 i = 0; i < listDepositERC20.size; i++) {
            if (listDepositERC20.list[i].tokens != address(0x0) && listDepositERC20.list[i].value > 0) {
                IERC20(listDepositERC20.list[i].tokens).transfer(owner, listDepositERC20.list[i].value);
            }
        }
    }
    
    function _closeNotCompleted() private {
        if (reward.tokens != address(0x0) && reward.value > 0) {
            IERC20(reward.tokens).transfer(owner, reward.value);
        }
        if (reward.tokens == address(0x0) && reward.value > 0) {
            address(uint160(address(owner))).transfer(reward.value);
        }
        if (startTimmingRequired.tokens != address(0x0) && startTimmingRequired.value > 0) {
            IERC20(startTimmingRequired.tokens).transfer(owner, startTimmingRequired.value);
        }
        
        for (uint256 i = 0; i < listDepositERC20.size; i++) {
            if (listDepositERC20.list[i].tokens != address(0x0) && listDepositERC20.list[i].value > 0) {
                IERC20(listDepositERC20.list[i].tokens).transfer(partner, listDepositERC20.list[i].value);
            }
        }
    }
    
    function depositEth(uint256 _index) public payable onlyPartner isLive onlyStartTimming {
        require(listDepositETH.size > _index, "TSC: Invalid required functions");
        require(listDepositETH.list[_index].deposited < listDepositETH.list[_index].value, "TSC: Deposit over");
        require(msg.value >= listDepositETH.list[_index].value);
        listDepositETH.list[_index].deposited += msg.value;
        passCount++;
        emit DepositEthCompleted(_index, listDepositETH.list[_index].deposited, block.timestamp);
    }
    
    function transferEth(uint256 _index) public payable onlyPartner isLive onlyStartTimming {
        require(listTransferETH.size > _index, "TSC: Invalid required functions");
        require(listTransferETH.list[_index].transfered == false, "TSC: Function is passed");
        require(msg.value >= listTransferETH.list[_index].value);
        listTransferETH.list[_index].transfered = true;
        listTransferETH.list[_index].receiver.transfer(listTransferETH.list[_index].value);
        passCount++;
        emit TransferEthCompleted(_index, listTransferETH.list[_index].receiver, listTransferETH.list[_index].value, block.timestamp);
    }
    
    function depositErc20(uint256 _index) public onlyPartner isLive onlyStartTimming {
        require(listDepositERC20.size > _index, "TSC: Invalid required functions");
        require(listDepositERC20.list[_index].deposited < listDepositERC20.list[_index].value, "TSC: Function is passed");
        
        require(IERC20(listDepositERC20.list[_index].tokens).transferFrom(msg.sender, address(this), listDepositERC20.list[_index].value), "TSC: Please approve transfer tokens for this contract");
        
        listDepositERC20.list[_index].deposited = listDepositERC20.list[_index].value;
        passCount++;
        emit DepositErc20Completed(_index, listDepositERC20.list[_index].tokens, listDepositERC20.list[_index].value, block.timestamp);
    }

    function transferErc20(uint256 _index) public onlyPartner isLive onlyStartTimming {
        require(listTransferERC20.size > _index, "TSC: Invalid required functions");
        require(listTransferERC20.list[_index].transfered == false, "TSC: Function is passed");
        
        require(IERC20(listTransferERC20.list[_index].tokens).transferFrom(msg.sender, listTransferERC20.list[_index].receiver, listTransferERC20.list[_index].value), "TSC: Please approve transfer tokens for this contract");
        
        listTransferERC20.list[_index].transfered = true;
        passCount++;
        emit TransferErc20Completed(_index, listTransferERC20.list[_index].receiver, listTransferERC20.list[_index].tokens, listTransferERC20.list[_index].value, block.timestamp);
    }
    
    function uploadSignature(uint256 _index, bytes memory _signature) public onlyPartner isLive onlyStartTimming {
        require(listUploadSignature.size > _index, "TSC: Invalid required functions");
        require(verify(listUploadSignature.list[_index].signer, listUploadSignature.list[_index].source, _signature));
        listUploadSignature.list[_index].signature = _signature;
        passCount++;
        emit SignatureUploaded(_index, listUploadSignature.list[_index].source, listUploadSignature.list[_index].signer, _signature, block.timestamp);
    }
    
    function verify(address _signer, bytes32 _messageHash, bytes memory _signature) private pure returns (bool) {
        return recoverSigner(_messageHash, _signature) == _signer;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    
    function isPassDepositErc20(uint256 _index) public view returns(bool) {
        require(listDepositERC20.size > _index, "TSC: Invalid required functions");
        return listDepositERC20.list[_index].value <= listDepositERC20.list[_index].deposited;
    }
    
    function isPassDepositEth(uint256 _index) public view returns(bool) {
        require(listDepositETH.size > _index, "TSC: Invalid required functions");
        return listDepositETH.list[_index].value <= listDepositETH.list[_index].deposited;
    }
    
    function isPassTransferEth(uint256 _index) public view returns(bool) {
        require(listTransferETH.size > _index, "TSC: Invalid required functions");
        return listTransferETH.list[_index].transfered;
    }

    function isPassTransferErc20(uint256 _index) public view returns(bool) {
        require(listTransferERC20.size > _index, "TSC: Invalid required functions");
        return listTransferERC20.list[_index].transfered;
    }
    
    function isPassSignature(uint256 _index) public view returns(bool) {
        require(listUploadSignature.size > _index, "TSC: Invalid required functions");
        return listUploadSignature.list[_index].signature.length > 0;
    }
    
    function listDepositEthSize() public view returns(uint256) {
        return listDepositETH.size;
    }
    
    function listDepositErc20Size() public view returns(uint256) {
        return listDepositERC20.size;
    }
    
    function listTransferEthSize() public view returns(uint256) {
        return listTransferETH.size;
    }

    function listTransferErc20Size() public view returns(uint256) {
        return listTransferERC20.size;
    }
    
    function listUploadSignatureSize() public view returns(uint256) {
        return listUploadSignature.size;
    }
    
    function depositEthFunction(uint256 _index) public view returns(uint256 _value, string memory _description, uint256 _deposited) {
        require(listDepositETH.size > _index, "TSC: Invalid required functions");
        
        _value = listDepositETH.list[_index].value;
        _description = listDepositETH.list[_index].description;
        _deposited = listDepositETH.list[_index].deposited;
    }
    
    function depositErc20Function(uint256 _index) public view returns(address _tokens, uint256 _value, string memory _symbol,string memory _description, uint256 _deposited) {
        require(listDepositERC20.size > _index, "TSC: Invalid required functions");
        _tokens = listDepositERC20.list[_index].tokens;
        _value = listDepositERC20.list[_index].value;
        _description = listDepositERC20.list[_index].description;
        _deposited = listDepositERC20.list[_index].deposited;
        if (_tokens != address(0x0)) {
            _symbol = IERC20(_tokens).symbol();
        }
    }
    
    function transferEthFunction(uint256 _index) public view returns(address _receiver, uint256 _value, string memory _description, bool _transfered) {
        require(listTransferETH.size > _index, "TSC: Invalid required functions");
        
        _receiver = listTransferETH.list[_index].receiver;
        _value = listTransferETH.list[_index].value;
        _description = listTransferETH.list[_index].description;
        _transfered = listTransferETH.list[_index].transfered;
    }

    function transferErc20Function(uint256 _index) public view returns(address _receiver, address _token, uint256 _value, string memory _description, bool _transfered) {
        require(listTransferERC20.size > _index, "TSC: Invalid required functions");
        
        _receiver = listTransferERC20.list[_index].receiver;
        _token = listTransferERC20.list[_index].tokens;
        _value = listTransferERC20.list[_index].value;
        _description = listTransferERC20.list[_index].description;
        _transfered = listTransferERC20.list[_index].transfered;
    }
    
    function uploadSignatureFunction(uint256 _index) public view returns(address _signer, bytes32 _source, string memory _description, bytes memory _signature) {
        require(listUploadSignature.size > _index, "TSC: Invalid required functions");
        
        _signer = listUploadSignature.list[_index].signer;
        _source = listUploadSignature.list[_index].source;
        _description = listUploadSignature.list[_index].description;
        _signature = listUploadSignature.list[_index].signature;
    }

}

pragma solidity ^0.6.0;

import './Owned.sol';

contract TerminateContractTemplate is Owned {
    uint256 public expiration;
    constructor() public {
        expiration = 0;
    }
    
    function setExpiration(uint256 _expiration) public virtual onlyOwner  {
        expiration = _expiration;
    }
    
    function terminate() public virtual onlyOwner isOver {
        selfdestruct(owner);
    }
    
    modifier isLive() {
        require(expiration == 0 || block.timestamp < expiration, "Terminated: Time over");
        _;
    }
    
    modifier isOver() {
        require(expiration != 0 && block.timestamp > expiration, "Terminated: Contract is live");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    
    function symbol() external view returns (string memory);
    
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

pragma solidity ^0.6.0;

interface IExecute {
    function execute() external returns (bool);
    function revert() external returns (bool);
}

