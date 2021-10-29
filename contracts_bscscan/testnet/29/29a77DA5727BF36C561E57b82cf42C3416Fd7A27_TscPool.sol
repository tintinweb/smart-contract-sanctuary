// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TerminateContractTemplate.sol";
import "./interface/IExecute.sol";
import "./interface/ITSCPool.sol";

contract TSC is TerminateContractTemplate {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

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

    address public ownerPool;

    constructor(address _ownerPool) {
        ownerPool = _ownerPool;
    }

    event StartContract(uint256 timestamp);
    event StartTiming(uint256 timestamp);
    event SignatureUploaded(
        uint256 indexed _index,
        bytes32 _source,
        address _signers,
        bytes _signature,
        uint256 _timestamp
    );
    event DepositEthCompleted(
        uint256 indexed _index,
        uint256 _value,
        uint256 _timestamp
    );
    event DepositErc20Completed(
        uint256 indexed _index,
        address _tokens,
        uint256 _value,
        uint256 _timestamp
    );
    event TransferEthCompleted(
        uint256 indexed _index,
        address _receiver,
        uint256 _value,
        uint256 _timestamp
    );
    event TransferErc20Completed(
        uint256 indexed _index,
        address _receiver,
        address _tokens,
        uint256 _value,
        uint256 _timestamp
    );
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

    modifier onlyTokenOption(address _token) {
        require(
            ITSCPool(ownerPool).checkTokenOption(_token),
            "Token is not on the list options"
        );
        _;
    }

    function setExecuteContract(address payable _address)
        public
        onlyOwner
        onlyNotReady
        isLive
    {
        execute_contract = _address;
    }

    function setExpiration(uint256 _expiration)
        public
        virtual
        override
        onlyOwner
    {
        revert();
    }

    function setupAndStart(
        BasicInfoInput memory basicInfo,
        DepositERC20Input[] memory _depositErc20s,
        TransferERC20Input[] memory _transferErc20s,
        DepositETHInput[] memory _depositEths,
        TransferETHInput[] memory _transferEths,
        UploadSignatureInput[] memory _uploadSignatures
    ) external payable onlyOwner onlyNotReady isLive {
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
        _setUpDepositErc20Functions(_depositErc20s);
        _setupTransferErc20Functions(_transferErc20s);
        _setupDepositEthFunctions(_depositEths);
        _setupTransferEthFunctions(_transferEths);
        _setupUploadSignatureFunctions(_uploadSignatures);
        start();
    }

    function _setupBasic(
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
    ) private onlyTokenOption(_tokens_address_start) returns (bool) {
        require(_partner != address(0), "Partner address can not be zero!");
        require(
            _tokens_address_start != address(0),
            "Start token address can not be zero!"
        );
        title = _title;
        partner = _partner;
        description = _description;
        execute_contract = _execute_contract;

        timeout = _timeout;
        expiration = _deadline;
        startTimmingRequired = StartTimingRequired({
            tokens: _tokens_address_start,
            value: _tokens_amount_start
        });
        reward = Reward({tokens: _rewardToken, value: _rewardValue});
        return true;
    }

    function _setUpDepositErc20Functions(
        DepositERC20Input[] memory _depositErc20s
    ) private returns (bool) {
        for (uint256 i = 0; i < _depositErc20s.length; i++) {
            DepositERC20Input memory depositErc20Input = _depositErc20s[i];
            require(
                ITSCPool(ownerPool).checkTokenOption(depositErc20Input.tokens),
                "Token is not on the list options"
            );
            require(
                depositErc20Input.tokens != address(0x0),
                "TSC: ERC20 tokens address in Deposit ERC20 Function is required different 0x0"
            );
            require(
                depositErc20Input.value > 0,
                "TSC: value of ERC20 in Deposit ERC20 Function is required greater than 0"
            );
            listDepositERC20.list[i] = DepositERC20(
                depositErc20Input.tokens,
                depositErc20Input.value,
                depositErc20Input.description,
                0
            );
        }
        listDepositERC20.size = _depositErc20s.length;
        return true;
    }

    function _setupTransferErc20Functions(
        TransferERC20Input[] memory _transferErc20s
    ) private returns (bool) {
        for (uint256 i = 0; i < _transferErc20s.length; i++) {
            TransferERC20Input memory transferErc20Input = _transferErc20s[i];
            require(
                ITSCPool(ownerPool).checkTokenOption(transferErc20Input.tokens),
                "Token is not on the list options"
            );
            require(
                transferErc20Input.receiver != address(0x0),
                "TSC: receiver in  in Transfer Erc20 Function is required different 0x0"
            );
            require(
                transferErc20Input.tokens != address(0x0),
                "TSC: ERC20 tokens address in Transfer ERC20 Function is required different 0x0"
            );
            require(
                transferErc20Input.value > 0,
                "TSC: value of ETH in Transfer Erc20 Function is required greater than 0"
            );
            listTransferERC20.list[i] = TransferERC20(
                transferErc20Input.receiver,
                transferErc20Input.tokens,
                transferErc20Input.value,
                transferErc20Input.description,
                false
            );
        }
        listTransferERC20.size = _transferErc20s.length;
        return true;
    }

    function _setupDepositEthFunctions(DepositETHInput[] memory _depositEths)
        private
        returns (bool)
    {
        for (uint256 i = 0; i < _depositEths.length; i++) {
            DepositETHInput memory deposit = _depositEths[i];
            require(
                deposit.value > 0,
                "TSC: value of ETH in Deposit ETH Function is required greater than 0"
            );
            listDepositETH.list[i] = DepositETH(
                deposit.value,
                deposit.description,
                0
            );
        }
        listDepositETH.size = _depositEths.length;
        return true;
    }

    function _setupTransferEthFunctions(TransferETHInput[] memory _transferEths)
        private
        returns (bool)
    {
        for (uint256 i = 0; i < _transferEths.length; i++) {
            TransferETHInput memory transferEthInput = _transferEths[i];
            require(
                transferEthInput.receiver != address(0x0),
                "TSC: receiver in  in Transfer ETH Function is required different 0x0"
            );
            require(
                transferEthInput.value > 0,
                "TSC: value of ETH in Transfer ETH Function is required greater than 0"
            );
            listTransferETH.list[i] = TransferETH(
                transferEthInput.receiver,
                transferEthInput.value,
                transferEthInput.description,
                false
            );
        }
        listTransferETH.size = _transferEths.length;
        return true;
    }

    function _setupUploadSignatureFunctions(
        UploadSignatureInput[] memory _uploadSignatures
    ) private returns (bool) {
        for (uint256 i = 0; i < _uploadSignatures.length; i++) {
            UploadSignatureInput memory signature = _uploadSignatures[i];
            require(
                signature.signer != address(0x0),
                "TSC: signer in  in Upload Signature Function is required different 0x0"
            );
            listUploadSignature.list[i] = UploadSignature(
                signature.signer,
                signature.source,
                signature.description,
                ""
            );
        }
        listUploadSignature.size = _uploadSignatures.length;
        return true;
    }

    function start() public payable onlyOwner onlyNotReady isLive {
        require(
            startTimmingRequired.tokens != address(0x0),
            "TSC: Please setup ERC20 address to start"
        );
        require(timeout > 0, "TSC: Please setup time out");
        if (reward.tokens != address(0x0)) {
            IERC20(reward.tokens).safeTransferFrom(
                msg.sender,
                address(this),
                reward.value
            );
        } else {
            require(msg.value == reward.value, "TSC: Please add ETH reward");
        }
        ready = true;
        emit StartContract(block.timestamp);
    }

    function startTimming() external onlyPartner isLive {
        require(!isStartTimming, "TSC: Timming started");

        IERC20(startTimmingRequired.tokens).safeTransferFrom(
            msg.sender,
            address(this),
            startTimmingRequired.value
        );

        if (expiration > block.timestamp + timeout) {
            expiration = block.timestamp + timeout;
        }
        isStartTimming = true;
        emit StartTiming(block.timestamp);
    }

    function terminate() public override isOver onlyOwner {
        uint256 totalFunction = listDepositETH.size +
            listTransferETH.size +
            listDepositERC20.size +
            listTransferERC20.size +
            listUploadSignature.size;

        bool completed = totalFunction == passCount;
        emit ContractClosed(block.timestamp, completed);
        if (execute_contract != address(0)) {
            if (reward.tokens != address(0x0) && reward.value > 0) {
                IERC20(reward.tokens).safeTransfer(
                    execute_contract,
                    reward.value
                );
            }
            if (
                startTimmingRequired.tokens != address(0x0) &&
                startTimmingRequired.value > 0
            ) {
                IERC20(startTimmingRequired.tokens).safeTransfer(
                    execute_contract,
                    startTimmingRequired.value
                );
            }
            for (uint256 i = 0; i < listDepositERC20.size; i++) {
                if (
                    listDepositERC20.list[i].tokens != address(0x0) &&
                    listDepositERC20.list[i].value > 0
                ) {
                    IERC20(listDepositERC20.list[i].tokens).safeTransfer(
                        execute_contract,
                        listDepositERC20.list[i].value
                    );
                }
            }
            Address.sendValue(execute_contract, address(this).balance);
            if (completed) {
                bool success = IExecute(execute_contract).execute();
                require(success, "TSC: Execution contract execute fail");
            } else {
                bool success = IExecute(execute_contract).revert();
                require(success, "TSC: Execution contract execute fail");
            }
        } else {
            if (completed) {
                _closeCompleted();
            } else {
                _closeNotCompleted();
            }
        }
        if (completed) {
            selfdestruct(payable(owner()));
        } else {
            selfdestruct(partner);
        }
    }

    function _closeCompleted() private {
        if (reward.tokens != address(0x0) && reward.value > 0) {
            IERC20(reward.tokens).safeTransfer(partner, reward.value);
        }
        if (reward.tokens == address(0x0) && reward.value > 0) {
            Address.sendValue(partner, reward.value);
        }
        if (
            startTimmingRequired.tokens != address(0x0) &&
            startTimmingRequired.value > 0
        ) {
            IERC20(startTimmingRequired.tokens).safeTransfer(
                partner,
                startTimmingRequired.value
            );
        }

        for (uint256 i = 0; i < listDepositERC20.size; i++) {
            if (
                listDepositERC20.list[i].tokens != address(0x0) &&
                listDepositERC20.list[i].value > 0
            ) {
                IERC20(listDepositERC20.list[i].tokens).safeTransfer(
                    owner(),
                    listDepositERC20.list[i].value
                );
            }
        }
    }

    function _closeNotCompleted() private {
        if (reward.tokens != address(0x0) && reward.value > 0) {
            IERC20(reward.tokens).safeTransfer(owner(), reward.value);
        }
        if (reward.tokens == address(0x0) && reward.value > 0) {
            Address.sendValue(payable(owner()), reward.value);
        }
        if (
            startTimmingRequired.tokens != address(0x0) &&
            startTimmingRequired.value > 0
        ) {
            IERC20(startTimmingRequired.tokens).safeTransfer(
                owner(),
                startTimmingRequired.value
            );
        }

        for (uint256 i = 0; i < listDepositERC20.size; i++) {
            if (
                listDepositERC20.list[i].tokens != address(0x0) &&
                listDepositERC20.list[i].value > 0
            ) {
                IERC20(listDepositERC20.list[i].tokens).safeTransfer(
                    partner,
                    listDepositERC20.list[i].value
                );
            }
        }
    }

    function depositEth(uint256 _index)
        external
        payable
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listDepositETH.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            listDepositETH.list[_index].deposited <
                listDepositETH.list[_index].value,
            "TSC: Deposit over"
        );
        require(msg.value == listDepositETH.list[_index].value);
        listDepositETH.list[_index].deposited += msg.value;
        passCount++;
        emit DepositEthCompleted(
            _index,
            listDepositETH.list[_index].deposited,
            block.timestamp
        );
    }

    function transferEth(uint256 _index)
        external
        payable
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listTransferETH.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            !listTransferETH.list[_index].transfered,
            "TSC: Function is passed"
        );
        require(msg.value == listTransferETH.list[_index].value);
        listTransferETH.list[_index].transfered = true;
        passCount++;
        Address.sendValue(
            listTransferETH.list[_index].receiver,
            listTransferETH.list[_index].value
        );
        emit TransferEthCompleted(
            _index,
            listTransferETH.list[_index].receiver,
            listTransferETH.list[_index].value,
            block.timestamp
        );
    }

    function depositErc20(uint256 _index)
        external
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listDepositERC20.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            listDepositERC20.list[_index].deposited <
                listDepositERC20.list[_index].value,
            "TSC: Function is passed"
        );
        uint256 preBalance = IERC20(listDepositERC20.list[_index].tokens)
            .balanceOf(address(this));

        IERC20(listDepositERC20.list[_index].tokens).safeTransferFrom(
            msg.sender,
            address(this),
            listDepositERC20.list[_index].value
        );

        listDepositERC20.list[_index].deposited =
            IERC20(listDepositERC20.list[_index].tokens).balanceOf(
                address(this)
            ) -
            preBalance;
        if (
            listDepositERC20.list[_index].deposited >=
            listDepositERC20.list[_index].value
        ) {
            passCount++;
            emit DepositErc20Completed(
                _index,
                listDepositERC20.list[_index].tokens,
                listDepositERC20.list[_index].value,
                block.timestamp
            );
        }
    }

    function transferErc20(uint256 _index)
        external
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listTransferERC20.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            !listTransferERC20.list[_index].transfered,
            "TSC: Function is passed"
        );
        listTransferERC20.list[_index].transfered = true;
        passCount++;
        IERC20(listTransferERC20.list[_index].tokens).safeTransferFrom(
            msg.sender,
            listTransferERC20.list[_index].receiver,
            listTransferERC20.list[_index].value
        );
        emit TransferErc20Completed(
            _index,
            listTransferERC20.list[_index].receiver,
            listTransferERC20.list[_index].tokens,
            listTransferERC20.list[_index].value,
            block.timestamp
        );
    }

    function uploadSignature(uint256 _index, bytes memory _signature)
        external
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listUploadSignature.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            verify(
                listUploadSignature.list[_index].signer,
                listUploadSignature.list[_index].source,
                _signature
            )
        );
        listUploadSignature.list[_index].signature = _signature;
        passCount++;
        emit SignatureUploaded(
            _index,
            listUploadSignature.list[_index].source,
            listUploadSignature.list[_index].signer,
            _signature,
            block.timestamp
        );
    }

    function verify(
        address _signer,
        bytes32 _messageHash,
        bytes memory _signature
    ) private pure returns (bool) {
        return _messageHash.recover(_signature) == _signer;
    }

    function isPassDepositErc20(uint256 _index) external view returns (bool) {
        require(
            listDepositERC20.size > _index,
            "TSC: Invalid required functions"
        );
        return
            listDepositERC20.list[_index].value <=
            listDepositERC20.list[_index].deposited;
    }

    function isPassDepositEth(uint256 _index) external view returns (bool) {
        require(
            listDepositETH.size > _index,
            "TSC: Invalid required functions"
        );
        return
            listDepositETH.list[_index].value <=
            listDepositETH.list[_index].deposited;
    }

    function isPassTransferEth(uint256 _index) external view returns (bool) {
        require(
            listTransferETH.size > _index,
            "TSC: Invalid required functions"
        );
        return listTransferETH.list[_index].transfered;
    }

    function isPassTransferErc20(uint256 _index) external view returns (bool) {
        require(
            listTransferERC20.size > _index,
            "TSC: Invalid required functions"
        );
        return listTransferERC20.list[_index].transfered;
    }

    function isPassSignature(uint256 _index) external view returns (bool) {
        require(
            listUploadSignature.size > _index,
            "TSC: Invalid required functions"
        );
        return listUploadSignature.list[_index].signature.length > 0;
    }

    function listDepositEthSize() external view returns (uint256) {
        return listDepositETH.size;
    }

    function listDepositErc20Size() external view returns (uint256) {
        return listDepositERC20.size;
    }

    function listTransferEthSize() external view returns (uint256) {
        return listTransferETH.size;
    }

    function listTransferErc20Size() external view returns (uint256) {
        return listTransferERC20.size;
    }

    function listUploadSignatureSize() external view returns (uint256) {
        return listUploadSignature.size;
    }

    function depositEthFunction(uint256 _index)
        external
        view
        returns (
            uint256 _value,
            string memory _description,
            uint256 _deposited
        )
    {
        require(
            listDepositETH.size > _index,
            "TSC: Invalid required functions"
        );

        _value = listDepositETH.list[_index].value;
        _description = listDepositETH.list[_index].description;
        _deposited = listDepositETH.list[_index].deposited;
    }

    function depositErc20Function(uint256 _index)
        external
        view
        returns (
            address _tokens,
            uint256 _value,
            string memory _symbol,
            string memory _description,
            uint256 _deposited
        )
    {
        require(
            listDepositERC20.size > _index,
            "TSC: Invalid required functions"
        );
        _tokens = listDepositERC20.list[_index].tokens;
        _value = listDepositERC20.list[_index].value;
        _description = listDepositERC20.list[_index].description;
        _deposited = listDepositERC20.list[_index].deposited;
        if (_tokens != address(0x0)) {
            _symbol = ERC20(_tokens).symbol();
        }
    }

    function transferEthFunction(uint256 _index)
        external
        view
        returns (
            address _receiver,
            uint256 _value,
            string memory _description,
            bool _transfered
        )
    {
        require(
            listTransferETH.size > _index,
            "TSC: Invalid required functions"
        );

        _receiver = listTransferETH.list[_index].receiver;
        _value = listTransferETH.list[_index].value;
        _description = listTransferETH.list[_index].description;
        _transfered = listTransferETH.list[_index].transfered;
    }

    function transferErc20Function(uint256 _index)
        external
        view
        returns (
            address _receiver,
            address _token,
            uint256 _value,
            string memory _description,
            bool _transfered
        )
    {
        require(
            listTransferERC20.size > _index,
            "TSC: Invalid required functions"
        );

        _receiver = listTransferERC20.list[_index].receiver;
        _token = listTransferERC20.list[_index].tokens;
        _value = listTransferERC20.list[_index].value;
        _description = listTransferERC20.list[_index].description;
        _transfered = listTransferERC20.list[_index].transfered;
    }

    function uploadSignatureFunction(uint256 _index)
        external
        view
        returns (
            address _signer,
            bytes32 _source,
            string memory _description,
            bytes memory _signature
        )
    {
        require(
            listUploadSignature.size > _index,
            "TSC: Invalid required functions"
        );

        _signer = listUploadSignature.list[_index].signer;
        _source = listUploadSignature.list[_index].source;
        _description = listUploadSignature.list[_index].description;
        _signature = listUploadSignature.list[_index].signature;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TSC.sol";

contract TscPool is Ownable {
    event Created(address indexed _creator, address _contracts);
    event AddTokenOptions(address[] _tokenOptions);
    event RemoveTokenOptions(address _token);

    mapping(address => bool) public tokenOptions;

    function setTokenOptions(address[] memory _tokenOptions) public onlyOwner {
        for (uint256 i = 0; i < _tokenOptions.length; i++) {
            tokenOptions[_tokenOptions[i]] = true;
        }
        emit AddTokenOptions(_tokenOptions);
    }

    function removeTokenOption(address _token) public {
        require(tokenOptions[_token], "TSCPool: This token is not on the list");
        tokenOptions[_token] = false;
        emit RemoveTokenOptions(_token);
    }

    function checkTokenOption(address _token) public view returns (bool) {
        return tokenOptions[_token];
    }

    function create() external returns (address) {
        TSC contracts = new TSC(address(this));
        contracts.transferOwnership(msg.sender);
        emit Created(msg.sender, address(contracts));
        return address(contracts);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TerminateContractTemplate is Ownable {
    uint256 public expiration;

    constructor() {}

    function setExpiration(uint256 _expiration) public virtual onlyOwner {
        expiration = _expiration;
    }

    function terminate() public virtual onlyOwner isOver {
        selfdestruct(payable(owner()));
    }

    modifier isLive() {
        require(
            expiration == 0 || block.timestamp <= expiration,
            "Terminated: Time over"
        );
        _;
    }

    modifier isOver() {
        require(
            expiration != 0 && block.timestamp > expiration,
            "Terminated: Contract is live"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IExecute {
    function execute() external returns(bool success);

    function revert() external returns(bool success);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITSCPool {
    function checkTokenOption(address _token) external view returns (bool);

    function getFee() external view returns (uint256);

    function calculateFee(address _sender) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}