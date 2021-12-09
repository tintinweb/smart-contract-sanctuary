// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./Utils.sol";
import "./RedBlack.sol";
import "./TransferVerifier.sol";
import "./WithdrawalVerifier.sol";
import "./Treasury.sol";

contract Firn {
    using Utils for uint256;
    using Utils for Utils.Point;

    uint256 constant EPOCH_LENGTH = 120;
    mapping(bytes32 => Utils.Point[2]) acc; // main account mapping
    mapping(bytes32 => Utils.Point[2]) pending; // storage for pending transfers
    mapping(bytes32 => uint256) lastRollOver;
    bytes32[] nonces; // would be more natural to use a mapping (really a set), but they can't be deleted / reset!
    uint256 lastGlobalUpdate = 0; // will be also used as a proxy for "current epoch", seeing as rollovers will be anticipated

    // could actually deploy the below two on-the-fly, but the gas would be too large in the deployment transaction.
    TransferVerifier immutable transferVerifier;
    WithdrawalVerifier immutable withdrawalVerifier;
    Treasury immutable treasury = new Treasury("Firn Token", "FIRN"); // arguments

    event TransferOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D);
    event WithdrawalOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D, uint256 amount, address recipient);

    address owner;
    uint32 fee;

    RedBlack immutable tree = new RedBlack(address(this));
    struct Info {
        uint256 epoch;
        uint32 amount; // really it's not crucial that this be uint32
        uint256 index; // index in the list
    }
    mapping(bytes32 => Info) public info; // public key --> deposit info
    mapping(uint256 => bytes32[]) public lists; // epoch --> list of depositing accounts
    function lengths(uint256 epoch) external view returns (uint256) { // see https://ethereum.stackexchange.com/a/20838.
        return lists[epoch].length;
    }

    constructor(address _ip, uint32 _fee) {
        transferVerifier = new TransferVerifier(_ip);
        withdrawalVerifier = new WithdrawalVerifier(_ip);
        owner = msg.sender;
        fee = _fee;
    }

    function administrate(address _owner, uint32 _fee) external {
        require(msg.sender == owner, "Forbidden ownership transfer.");
        owner = _owner;
        fee = _fee;
    }

    function simulateAccounts(bytes32[] calldata Y, uint256 epoch) external view returns (bytes32[2][] memory result) {
        // interestingly, we lose no efficiency by accepting compressed, because we never have to decompress.
        result = new bytes32[2][](Y.length);
        for (uint256 i = 0; i < Y.length; i++) {
            Utils.Point[2] memory temp = acc[Y[i]];
            if (lastRollOver[Y[i]] < epoch) {
                temp[0] = temp[0].add(pending[Y[i]][0]);
                temp[1] = temp[1].add(pending[Y[i]][1]);
            }
            result[i][0] = Utils.compress(temp[0]);
            result[i][1] = Utils.compress(temp[1]);
        }
    }

    function rollOver(bytes32 Y) private {
        uint256 epoch = block.timestamp / EPOCH_LENGTH;
        if (lastRollOver[Y] < epoch) {
            acc[Y][0] = acc[Y][0].add(pending[Y][0]);
            acc[Y][1] = acc[Y][1].add(pending[Y][1]);
            delete pending[Y]; // pending[Y] = [Utils.G1Point(0, 0), Utils.G1Point(0, 0)];
            lastRollOver[Y] = epoch;
        }
    }

    function deposit(bytes32 Y, bytes32[2] calldata signature) external payable {
        require(msg.value >= 1e18 && msg.value % 1e16 == 0, "Invalid deposit amount.");

        Utils.Point memory pub = Utils.decompress(Y);
        Utils.Point memory K = Utils.g().mul(uint256(signature[1])).add(pub.mul(uint256(signature[0]).neg()));
        uint256 c = uint256(keccak256(abi.encode("Welcome to FIRN", address(this), Y, K))).mod();
        require(bytes32(c) == signature[0], "Signature failed to verify.");

        uint256 epoch = block.timestamp / EPOCH_LENGTH;
        if (lastGlobalUpdate < epoch) {
            lastGlobalUpdate = epoch;
            delete nonces;
        }
        rollOver(Y);

        Utils.Point[2] storage scratch = pending[Y];
        uint256 credit = msg.value / 1e16;
        scratch[0] = scratch[0].add(Utils.g().mul(credit));
        uint256 balance = address(this).balance / 1e16; // an integer
        require(balance <= 0xFFFFFFFF, "Escrow pool now too large.");

        Info storage current = info[Y];
        bytes32[] storage list;
        if (current.epoch > 0) { // this guy has deposited before... remove him from old list
            list = lists[current.epoch];
            list[current.index] = list[list.length - 1];
            list.pop();
            if (list.length == 0) tree.remove(current.epoch);
            else if (current.index < list.length) info[list[current.index]].index = current.index;
        }
        current.epoch = epoch;
        current.amount += uint32(credit);
        if (!tree.exists(epoch)) {
            tree.insert(epoch);
        }
        list = lists[epoch];
        current.index = list.length;
        list.push(Y);

        uint256 zeros = 32; // in {0, ... ,}
        for (uint256 i = 0; i < 32; i++) {
            // use the balance _before_ the deposit hit to calculate the leverage factor.
            if (balance - credit >> 32 - 1 - i & 0x01 == 0x01) {
                zeros = i;
                break;
            }
        }
        credit <<= zeros >> 1;
        credit *= 1e16;
        treasury.mint(msg.sender, credit);
    }

    function transfer(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes32 u, uint256 epoch, uint32 tip, bytes calldata proof) external {
        require(epoch == block.timestamp / EPOCH_LENGTH, "Wrong epoch.");

        if (lastGlobalUpdate < epoch) {
            lastGlobalUpdate = epoch;
            delete nonces;
        }
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] != u, "Nonce already seen.");
        }
        nonces.push(u);

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            rollOver(Y[i]);

            statement.Y[i] = Utils.decompress(Y[i]);
            statement.C[i] = Utils.decompress(C[i]);
            statement.CLn[i] = acc[Y[i]][0].add(statement.C[i]);
            statement.CRn[i] = acc[Y[i]][1].add(statement.D);
            // mutate their pending, in advance of success.
            Utils.Point[2] storage scratch = pending[Y[i]];
            scratch[0] = scratch[0].add(statement.C[i]);
            scratch[1] = scratch[1].add(statement.D);
            // pending[Y[i]] = scratch; // can't do this, so have to use 2 sstores _anyway_ (as in above)
        }
        statement.epoch = epoch;
        statement.u = Utils.decompress(u);
        statement.fee = tip;

        transferVerifier.verify(statement, Utils.deserializeTransfer(proof));
        payable(msg.sender).transfer(uint256(tip) * 1e16);

        emit TransferOccurred(Y, C, D);
    }

    function withdraw(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes32 u, uint256 epoch, uint32 amount, address recipient, uint32 tip, bytes calldata proof) external {
        require(epoch == block.timestamp / EPOCH_LENGTH, "Wrong epoch."); // this doesn't actually provide security; it's just a convenience method

        if (lastGlobalUpdate < epoch) {
            lastGlobalUpdate = epoch;
            delete nonces;
        }
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] != u, "Nonce already seen.");
        }
        nonces.push(u);

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            rollOver(Y[i]);

            statement.Y[i] = Utils.decompress(Y[i]);
            statement.C[i] = Utils.decompress(C[i]);
            statement.CLn[i] = acc[Y[i]][0].add(statement.C[i]);
            statement.CRn[i] = acc[Y[i]][1].add(statement.D);
            // mutate their pending, in advance of success.
            Utils.Point[2] storage scratch = pending[Y[i]];
            scratch[0] = scratch[0].add(statement.C[i]);
            scratch[1] = scratch[1].add(statement.D);
            // pending[Y[i]] = scratch; // can't do this, so have to use 2 sstores _anyway_ (as in above)
        }
        statement.epoch = epoch;
        statement.u = Utils.decompress(u);
        statement.fee = tip + (amount >> fee); // for the purposes of the zkp

        withdrawalVerifier.verify(recipient, amount, statement, Utils.deserializeWithdrawal(proof));

        payable(msg.sender).transfer(uint256(tip) * 1e16);
        payable(recipient).transfer(uint256(amount) * 1e16);
        payable(treasury).transfer(uint256(amount >> fee) * 1e16);
//        (bool sent,) = payable(treasury).call{value: uint256(amount >> fee) * 1e16}(""); // fallback
//        require(sent, "Failed to send.");

        emit WithdrawalOccurred(Y, C, D, amount, recipient);
    }
}