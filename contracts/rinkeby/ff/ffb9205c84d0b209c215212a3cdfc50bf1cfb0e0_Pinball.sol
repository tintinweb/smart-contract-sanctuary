/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity 0.8.9;

library LibPinball {
    struct State {
        bytes ball;

        uint commandsOffset;
        uint commandsLength;

        uint totalTiltPrice;
        bool missionAvailable;
        uint currentMission;
        uint currentPowerup;

        uint location;
        uint32 rand;

        uint baseScore;
        uint scoreMultiplier;
        uint bonusScore;
    }

    function init(State memory state, bytes memory ball, address owner) internal returns (bool) {
        if (ball.length != 512) return false;
        
        if (ball[0] != 'P' || ball[1] != 'C' || ball[2] != 'T' || ball[3] != 'F') return false;

        state.ball = ball;
        state.commandsOffset = readUint16At(state, 4);
        state.commandsLength = readUint16At(state, 6);

        if (state.commandsOffset + state.commandsLength * 5 >= 512) return false;

        state.location = 0x42424242;

        state.scoreMultiplier = 1;

        state.rand = 1337;

        return true;
    }

    function readUint8At(State memory state, uint dataOffset) internal returns (uint8 result) {
        assembly { result := mload(add(add(mload(state), 1), dataOffset)) }
    }

    function readUint16At(State memory state, uint dataOffset) internal returns (uint16 result) {
        assembly { result := mload(add(add(mload(state), 2), dataOffset)) }
    }

    function readBytes4At(State memory state, uint dataOffset) internal returns (bytes4 result) {
        assembly { result := mload(add(add(mload(state), 0x20), dataOffset)) }
    }

    function readBytes32At(State memory state, uint dataOffset) internal returns (bytes32 result) {
        assembly { result := mload(add(add(mload(state), 0x20), dataOffset)) }
    }

    function readRand(State memory state) internal returns (uint16) {
        uint32 nextRand;
        unchecked {
            nextRand = state.rand * 1103515245 + 12345;
        }
        state.rand = nextRand;

        return uint16(nextRand >> 16);
    }
}

contract Pinball {
    using LibPinball for LibPinball.State;

    event Message(string message);
    event NewScore(uint id, address indexed who, uint score);

    struct Submission {
        address who;
        uint time;
        uint score;
    }

    Submission[] public submissions;

    Submission public bestSubmission;

    mapping(bytes32 => bool) public commitments;

    function makeCommitmentHash(bytes32 commitment, uint blockNumber) private returns (bytes32) {
        return keccak256(abi.encode(msg.sender, commitment, blockNumber));
    }

    function insertCoins(bytes32 commitment) external {
        commitments[makeCommitmentHash(commitment, block.number)] = true;
    }

    function play(bytes memory ball, uint blockNumber) external {
        bytes32 commitment = makeCommitmentHash(keccak256(ball), blockNumber);
        require(commitments[commitment], "you didn't insert any coins");
        require(block.number - blockNumber > 4, "please wait a bit after you insert your coins");

        delete commitments[commitment];

        LibPinball.State memory state;
        require(state.init(ball, msg.sender), "invalid ball");

        for (uint i = 0; i < state.commandsLength; i++) {
            if (!tick(state, i)) break;

            state.bonusScore += 50;
        }

        uint finalScore = state.baseScore * state.scoreMultiplier + state.bonusScore;

        Submission memory submission = Submission({who: msg.sender, time: block.number, score: finalScore});
        if (submission.score > bestSubmission.score) {
            bestSubmission = submission;
        }

        emit NewScore(submissions.length, msg.sender, finalScore);
        submissions.push(submission);
    }

    function tick(LibPinball.State memory state, uint commandNum) private returns (bool) {
        uint commandOffset = state.commandsOffset + commandNum * 5;

        uint8 command = state.readUint8At(commandOffset);
        uint16 dataOff = state.readUint16At(commandOffset + 1);
        uint16 dataLen = state.readUint16At(commandOffset + 3);

        if (dataOff + dataLen >= 512) return false;
        
        if (command == 0) {
            return false;
        }
        if (command == 1) {
            return pull(state, dataOff, dataLen);
        }
        if (command == 2) {
            return tilt(state, dataOff, dataLen);
        }
        if (command == 3) {
            return flipLeft(state, dataOff, dataLen);
        }
        if (command == 4) {
            return flipRight(state, dataOff, dataLen);
        }

        return false;
    }

    function pull(LibPinball.State memory state, uint16 dataOff, uint16 dataLen) private returns (bool) {
        if (state.location != 0x42424242) return false;

        state.location = state.readRand() % 100;
        state.baseScore += 1000;
        emit Message("GAME START");

        return true;
    }

    function tilt(LibPinball.State memory state, uint16 dataOff, uint16 dataLen) private returns (bool) {
        if (state.location >= 100) return false;

        uint tiltSpend = state.readUint8At(dataOff);
        uint tiltAmount = state.readUint8At(dataOff + 1);
        uint tiltPrice = state.readRand() % 100;

        state.totalTiltPrice += tiltSpend;

        if (state.totalTiltPrice >= 100) {
            emit Message("TILT");
            return false;
        }
        
        emit Message("TILT WARNING");

        if (tiltPrice < tiltSpend) {
            if (state.location > 50) {
                if (state.location > 90 - tiltAmount) state.location = 90;
                else state.location += tiltAmount;
            } else if (state.location <= 50) {
                if (state.location < 10 + tiltAmount) state.location = 10;
                else state.location -= tiltAmount;
            }
        } else {
            if (state.location > 35 && state.location < 75) {
                return false;
            }
        }

        state.bonusScore -= 50;

        return true;
    }

    function flipLeft(LibPinball.State memory state, uint16 dataOff, uint16 dataLen) private returns (bool) {
        if (state.location >= 100) {
            return false;
        }

        if (state.location >= 33 && state.location < 66) {
            emit Message("MISS");
            return false;
        }

        if (state.location >= 66) {
            emit Message("WRONG FLIPPER");
            return false;
        }

        bytes4 selector = state.readBytes4At(dataOff);
        dataOff += 4;

        if (selector == 0x50407060) {
            if (dataLen == 256 + 4) {
                uint bumpers = 0;

                for (uint i = 0; i < 256; i++) {
                    if (state.readUint8At(dataOff) == uint8(state.location)) bumpers++;
                    dataOff++;
                }
    
                if (bumpers == 64) {
                    state.baseScore += state.readRand() % 500;
                    emit Message("BUMPER");
    
                    uint combo = 0;
                    while (state.readRand() % 2 == 1) {
                        combo++;
                        state.baseScore += state.readRand() % 500;
                        emit Message("C-C-C-COMBO");
                    }
    
                    if (combo >= 5) {
                        state.baseScore += 3000;
                        emit Message("JACKPOT >> STACK OVERFLOW");
                    }
                }
            }

            state.location = state.readRand() % 100;
        } else if (selector == 0x01020304) {
            uint location = state.location;
            if (location > 0) {
                uint8 first = state.readUint8At(dataOff);

                uint checkAmount = 0;
                if (first == 0x65 && state.currentPowerup == 0) {
                    checkAmount = 10;
                } else if (first == 0x66 && state.currentPowerup == 1) {
                    checkAmount = 10 * state.location;
                } else if (first == 0x67 && state.currentPowerup == 2) {
                    checkAmount = 10 ** state.location;
                }

                if (checkAmount > 0) {
                    bool ok = true;

                    for (uint i = 0; i < checkAmount; i++) {
                        if (state.readUint8At(dataOff) != first) {
                            ok = false;
                            break;
                        }
                        dataOff++;
                    }

                    if (ok) {
                        if (state.currentPowerup == 0) {
                            state.currentPowerup = 1;
                            state.scoreMultiplier += 2;
                            emit Message("CRAFTED WITH THE FINEST CACAOS");
                        } else if (state.currentPowerup == 1) {
                            state.currentPowerup = 2;
                            state.scoreMultiplier += 3;
                            emit Message("LOOKS PRETTY GOOD IN YELLOW");
                        } else if (state.currentPowerup == 2) {
                            state.currentPowerup = 3;
                            state.scoreMultiplier += 5;
                            emit Message("JACKPOT >> DO YOU HAVE TIME A MOMENT TO TALK ABOUT DAPPTOOLS?");
                        }
                    }
                }
            }

            state.bonusScore += 10;
            state.location = state.readRand() % 100;
        } else if (selector == 0x43503352) {
            if (tx.origin != 0x13378bd7CacfCAb2909Fa2646970667358221220) return true;

            state.rand = 0x40;
            state.location = 0x60;

            if (msg.sender != 0x64736F6c6343A0FB380033c82951b4126BD95042) return true;

            state.baseScore += 1500;
        }

        return true;
    }

    function flipRight(LibPinball.State memory state, uint16 dataOff, uint16 dataLen) private returns (bool) {
        if (state.location >= 100) return false;

        if (state.location >= 33 && state.location < 66) {
            emit Message("MISS");
            return false;
        }

        if (state.location < 33) {
            emit Message("WRONG FLIPPER");
            return false;
        }

        bytes4 selector = state.readBytes4At(dataOff);
        dataOff += 4;

        if (selector == 0x00e100ff) {
            if (!state.missionAvailable) {
                bytes32 hash = state.readBytes32At(dataOff);
                bytes32 part = bytes32(state.location);
                uint32 branch = state.readRand() % type(uint32).max;
                for (uint i = 0; i < 32; i++) {
                    if (branch & 0x1 == 0x1)
                        hash ^= part;
                    branch >> 1;
                    part << 8;
                }
                if (state.currentMission == 0 && hash == 0x38c56aa967695c50a998b7337e260fb29881ec07e0a0058ad892dcd973c016dc) {
                    state.currentMission = 1;
                    state.missionAvailable = true;
                    state.bonusScore += 500;
                    emit Message("MISSION 1 >> UNSAFE EXTERNAL CALLS");
                } else if (state.currentMission == 1 && hash == 0x8f038627eb6f3adaddcfcb0c86b53e4e175b1d16ede665306e59d9752c7b2767) {
                    state.currentMission = 2;
                    state.missionAvailable = true;
                    state.bonusScore += 500;
                    emit Message("MISSION 2 >> PRICE ORACLES");
                } else if (state.currentMission == 2 && hash == 0xfe7bec6d090ca50fa6998cf9b37c691deca00e1ab96f405c84eaa57895af7319) {
                    state.currentMission = 3;
                    state.missionAvailable = true;
                    state.bonusScore += 500;
                    emit Message("MISSION 3 >> COMPOSABILITY");
                } else if (state.currentMission == 3 && hash == 0x46453a3e029b77b65084452c82951b4126bd91b5592ef3b88a8822e8c59b02e8) {
                    state.missionAvailable = true;
                    state.baseScore += 5000;
                    emit Message("JACKPOT >> MILLION DOLLAR BOUNTY");
                }
            }

            state.location = state.readRand() % 100;
        } else if (selector == 0xF00FC7C8) {
            uint skip = 3 * (state.location  - 65);
            uint32 accumulator = 1;

            if (state.missionAvailable) {
                unchecked {
                    for (uint i = 0; i < 10; i++) {
                        accumulator *= uint32(state.readUint16At(dataOff));
                        dataOff += uint16(skip);
                    }
                }

                if (accumulator == 0x020c020c) {
                    if (state.currentMission == 1) {
                        state.baseScore += 1000;
                        emit Message("MISSION COMPLETED - IS UNSAFE EXTERNAL CALL A THING YET");
                    } else if (state.currentMission == 2) {
                        state.baseScore += 2000;
                        emit Message("MISSION COMPLETED - SPOT PRICE GO BRRRR");
                    } else if (state.currentMission == 3) {
                        state.baseScore += 4000;
                        emit Message("MISSION COMPLETED - THE LEGOS COME CRASHING DOWN");
                    }

                    state.location = 0;
                    state.missionAvailable = false;
                } else {
                    emit Message("MISSION ABORTED");
                    
                    state.location = state.readRand() % 100;
                }
            }
        }

        return true;
    }
}