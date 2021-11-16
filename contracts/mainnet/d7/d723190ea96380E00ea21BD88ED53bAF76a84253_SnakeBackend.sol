// SPDX-License-Identifier: CC-BY-4.0

pragma solidity >= 0.8.0;

import "./IArcadeBackend.sol";

contract SnakeBackend is IArcadeBackend {

    address controller;

    string constant svgWrapper1 = "<svg viewBox='0 0 11 17' fill='none' xmlns='http://www.w3.org/2000/svg'><rect x='.5' y='.5' width='10' height='16' fill='#221D42'/><rect x='.5' y='.5' width='10' height='10' fill='#07060E'/><rect x='.5' y='.5' width='10' height='10' stroke='#221D42'/><rect x='.5' y='.5' width='10' height='16' stroke='#221D42'/>";
    string constant svgWrapper2 = "</g></svg>";

    string constant pixelTemplate0a = "<rect><animate id='stop' being='0s' dur='";
    string constant pixelTemplate0b = "s' fill='freeze'/></rect>";
    string constant pixelTemplate1Head = "<rect rx='0.2' width='1' opacity='0' height='1' fill='#5E05CE'><animateMotion begin='";
    string constant pixelTemplate1 = "<rect rx='0.2' width='1' opacity='0' height='1' fill='#8C3BE5'><animateMotion begin='";
    string constant pixelTemplate2 = "s' end='stop.end' dur='";
    string constant pixelTemplate3 = "s' fill='freeze'><mpath href='#p1'/></animateMotion><animate begin='";
    string constant pixelTemplate4 = "s' attributeName='opacity' values='1' fill='freeze' /></rect>";

    string constant pixelTemplateStatic1Head = "<rect rx='0.2' width='1' height='1' fill='#5e05ce' x='";
    string constant pixelTemplateStatic1 = "<rect rx='0.2' width='1' height='1' fill='#8c3be5' x='";
    string constant pixelTemplateStatic2 = "' y='";
    string constant pixelTemplateStatic3 = "' />";

    string constant blinkingAnimationTemplate1 = "<g><animate attributeName='opacity' values='0;1;' dur='1s' calcMode='discrete' begin='";
    string constant blinkingAnimationTemplate2 = "' repeatCount='5'/>";

    string constant applePixelTemplateStatic1 = "<g><rect rx='0.2' width='1' height='1' fill='#c82b76' x='";
    
    string  constant numbersTemplate1 = "<path d='M ";

    string  constant appleTemplate1 = "<rect rx='0.2' x='";
    string  constant appleTemplate2 = "' y='";
    string  constant appleTemplate3 = "' opacity='0' width='1' height='1' fill='#C82B76'><animate begin='";
    string  constant appleTemplate4 = "s' attributeName='opacity' values='1' fill='freeze' /><animate begin='";
    string  constant appleTemplate5 = "s' attributeName='opacity' values='0' fill='freeze' /></rect>";
    string  constant appleTemplate4alt = "s' attributeName='opacity' values='1' fill='freeze' /></rect>";


    string  constant animatedNumberTemplate1 = "' opacity='0' stroke='#fff'><animate begin='";
    string  constant animatedNumberTemplate2 = "s' attributeName='opacity' values='1' fill='freeze' /><animate begin='";
    string  constant animatedNumberTemplate3 = "s' attributeName='opacity' values='0' fill='freeze' /></path>";
    string  constant animatedNumberTemplate2alt = "s' attributeName='opacity' values='1' fill='freeze' /></path>";


    string  constant pathTemplate1 = "<path d='M ";
    string  constant pathTemplate2 = "' id='p1'/>";

    function getLeftNumber(uint number) internal pure returns (string memory _svgCode) {
       return [
            "2.5 11.5 h 2 v 4 h -2 v -4.5",
            "3 11.5 h 1.5 v 4.5",
            "2 11.5 h 2.5 v 2 h -2 v 2 h 2.5",
            "2 11.5 h 2.5 v 2 h -2.5 h 2.5 v 2 h -2.5",
            "2.5 11 v 2.5 h 2 v 2.5 v -5"
        ][number];
    }

    function getRightNumber(uint number) internal pure returns (string memory _svgCode) {
        return [
            "6 11.5 h 2.5 v 4 h -2 v -3.5",
            "7 11.5 h 1.5 v 4.5",
            "6 11.5 h 2.5 v 2 h -2 v 2 h 2.5",
            "6 11.5 h 2.5 v 2 h -2.5 h 2.5 v 2 h -2.5",
            "6.5 11 v 2.5 h 2 v -2.5 v 5",
            "9 11.5 h -2.5 v 2 h 2 v 2 h -2.5",
            "6.5 11 v 4.5 h 2 v -2 h -2.5",
            "6 11.5 h 2.5 v 2.5 M 7.5 14 v 2",
            "6 11.5 h 2.5 v 2 h -2 v -2.5 v 4.5 h 2 v -2.5",
            "9 13.5 h -2.5 v -2 h 2 v 4.5"
        ][number];
    }

    string constant numbersTemplate2 = "' stroke='#fff'/>";

    uint constant INITIAL_SNAIL_LENGTH = 3;
    uint constant GRID_SIZE = 11;
    uint constant appleShift = GRID_SIZE + 1;
    uint constant validRowSlotCount = GRID_SIZE - 2;
    uint constant SPEED = 256;
    uint constant MAX_INT = (1 << 256) - 1;
    uint constant validPositionsCount = validRowSlotCount * validRowSlotCount;
    uint[validPositionsCount] validPositions;
    
    uint WALL_MASK;

    modifier onlyController() {
        require(controller == msg.sender, "Not allowed.");
        _;
    }

    constructor (address _controller) {
        uint boundary = GRID_SIZE - 1;
        for(uint i = 0; i < GRID_SIZE; i++) {
            WALL_MASK = WALL_MASK | (1 << i);
            WALL_MASK = WALL_MASK | (1 << (i * GRID_SIZE));
            WALL_MASK = WALL_MASK | (1 << (boundary * GRID_SIZE + i));
            WALL_MASK = WALL_MASK | (1 << (i * GRID_SIZE + boundary));
        }
   
        uint lastPosition = 0;
        for(uint x = 1; x < GRID_SIZE - 1; x++) {
            for(uint y = 1; y < GRID_SIZE - 1; y++) {
                lastPosition = 1 << (x * GRID_SIZE) << y;
                validPositions[(x - 1) * validRowSlotCount + (y - 1)] = lastPosition;
            }
        }

        controller = _controller;
    }

    mapping(uint => uint) tokenIdToBlockHash;
    mapping(uint => uint) tokenIdToRandomness;
    mapping(uint => uint) tokenIdToStartingBlock;

    // ------- Minting logic -------

    function adress2uint(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }

    function extendSnail(uint head, uint appleBitmap, uint amountIndex, uint moveIndex) internal view returns (uint256, uint[600] memory) {
        uint amount = [GRID_SIZE, 1][amountIndex % 2];
        uint extendedBitmap = moveIndex == 0 ? 
            head | (head >> amount) | (head >> (amount * 2)) : 
            head | (head << amount) | (head << (amount * 2));
        if(isCollision(extendedBitmap, appleBitmap)) {
            return extendSnail(head, appleBitmap, amountIndex + 1, (amountIndex % 4) < 2 ? 0 : 1);
        }
        else {
            uint[600] memory extendedState;
            if (moveIndex == 0) {
                extendedState[0] = head >> (amount * 2);
                extendedState[1] = head >> amount;
            }
            else {
                extendedState[0] = head << (amount * 2);
                extendedState[1] = head << amount;
            }

            extendedState[2] = head;
        
            return  (extendedBitmap, extendedState);
        }
    }

    function gameConfiguration(uint startingBlock, uint blockHash, uint randomness) internal view returns (uint[600] memory _initialState, uint[100] memory _initialApples, uint _initialStateBitmap) {    
        uint appleIndex = randomness % validPositionsCount;
        uint initialAppleBitmap = validPositions[appleIndex];
        uint[100] memory initialApples;
        initialApples[0] = initialAppleBitmap;
        
        
        uint headIndex = randomness | blockHash;
        uint snailHead = validPositions[headIndex % validPositionsCount];
        if(isCollision(snailHead, initialAppleBitmap) && headIndex < MAX_INT) {
            snailHead = validPositions[(headIndex + 1) % validPositionsCount];
        }
        else if(isCollision(snailHead, initialAppleBitmap)) {
            snailHead = validPositions[(headIndex - 1) % validPositionsCount];
        }

        uint initialStateBitmap = 0;
        uint[600] memory initialState;
        uint extensionSeed = startingBlock % 4;
        uint amountIndex = extensionSeed % 2;
        uint moveIndex = extensionSeed < 2 ? 0 : 1;
        (initialStateBitmap, initialState) = extendSnail(snailHead, initialAppleBitmap, amountIndex, moveIndex);
        
        return (initialState, initialApples, initialStateBitmap);
    }

    // ----- Game logic ------
    
    function logg2(uint x) internal pure returns (uint y){
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }

    function getRightMost(uint bitmap) internal pure returns (uint bit) {
        return bitmap ^ ( bitmap & (bitmap - 1));
    }

    function decodePosition(uint positionMask) internal pure returns (uint[2] memory _position) {
        uint position = logg2(positionMask);

        return [position / GRID_SIZE, position % GRID_SIZE];
    }

    function decodeX(uint p) internal pure returns(uint x) {
        return (
            1 >> (2047 & p ^ p)
            | 2 >> (4192256 & p ^ p)
            | 4 >> (8585740288 & p ^ p)
            | 8 >> (17583596109824 & p ^ p)
            | 16 >> (36011204832919552 & p ^ p)
            | 32 >> (73750947497819242496 & p ^ p)
            | 64 >> (151041940475533808631808 & p ^ p)
            | 128 >> (309333894093893240077942784 & p ^ p)
            | 256 >> (633515815104293355679626821632 & p ^ p)
            | 512 >> (1297440389333592792431875730702336 & p ^ p)
            | 1024 >> (2657157917355198038900481496478384128 & p ^ p)
        );
    }

    function decodeY(uint p) internal pure returns(uint y) {
        return (
            (2047 & p)
            | (4192256 & p) >> 11
            | (8585740288 & p) >> 22
            | (17583596109824 & p) >> 33
            | (36011204832919552 & p) >> 44
            | (73750947497819242496 & p) >> 55
            | (151041940475533808631808 & p) >> 66
            | (309333894093893240077942784 & p) >> 77
            | (633515815104293355679626821632 & p) >> 88
            | (1297440389333592792431875730702336 & p) >> 99
            | (2657157917355198038900481496478384128 & p) >> 110
        );
    }

    function getUMovementsMask(uint point) internal pure returns (uint _mask) {
        uint movements = point << GRID_SIZE | point >> GRID_SIZE | point << 1 | point >> 1;
        
        return movements;
    }


    function getNextAIMove(uint stateBitmap, uint mouthBitmap, uint appleBitmap, uint tailBitmap) internal view returns (uint _newMouth) {
        uint mouthX = decodeX(mouthBitmap);
        uint mouthY = decodeY(mouthBitmap);

        uint targetX = decodeX(appleBitmap);
        uint targetY = decodeY(appleBitmap);

        if(mouthX < targetX && !isCollision(mouthBitmap << GRID_SIZE, stateBitmap)) {
            return mouthBitmap << GRID_SIZE;
        }
        else if(mouthX > targetX && !isCollision(mouthBitmap >> GRID_SIZE, stateBitmap)) {
            return mouthBitmap >> GRID_SIZE;
        }
        else if(mouthY < targetY && !isCollision(mouthBitmap << 1, stateBitmap)) {
            return mouthBitmap << 1;
        } 
        else if(mouthY > targetY && !isCollision(mouthBitmap >> 1, stateBitmap)) {
            return mouthBitmap >> 1;
        }

        targetX = decodeX(tailBitmap);
        targetY = decodeY(tailBitmap);

        if(mouthX < targetX && !isCollision(mouthBitmap << GRID_SIZE, stateBitmap)) {
            return mouthBitmap << GRID_SIZE;
        }
        else if(mouthX > targetX && !isCollision(mouthBitmap >> GRID_SIZE, stateBitmap)) {
            return mouthBitmap >> GRID_SIZE;
        }
        else if(mouthY < targetY && !isCollision(mouthBitmap << 1, stateBitmap)) {
            return mouthBitmap << 1;
        } 
        else if(mouthY > targetY && !isCollision(mouthBitmap >> 1, stateBitmap)) {
            return mouthBitmap >> 1;
        }

        uint movements = getUMovementsMask(mouthBitmap);
        uint valid = movements ^ ((movements & WALL_MASK) | (movements & stateBitmap));
        
        return getRightMost(valid | (1 << (GRID_SIZE * GRID_SIZE - 1)));

    }

    function encodeUPosition(uint x, uint y) internal pure returns (uint) {
        return 1 << (x * GRID_SIZE) + y;
    }

    function isCollision(uint point, uint stateSummary) internal view returns (bool _collision) {
        return ((WALL_MASK & point) | (point & stateSummary)) > 0;
    }

    function getNewApple(uint blockNumber, uint stateBitmap, uint currentStateLength) internal view returns (uint _newPosition) {
        uint seed = (blockNumber + currentStateLength) % validPositionsCount;
        uint newAppleBitmap = 1 << (seed + appleShift + 2 * (seed / validRowSlotCount));
        if(isCollision(newAppleBitmap, stateBitmap)) {
            return getRightMost(~stateBitmap - WALL_MASK);
        }

        return newAppleBitmap;
    }

    function getCurrentState(uint iteration, uint startingBlock, uint[600] memory currentState, uint currentStateBitmap, uint[100] memory apples) internal view returns (uint _points, uint _stateLength, uint[100] memory _keyTimes) {
        uint points = 0;
        uint currentStateLength = INITIAL_SNAIL_LENGTH;
        uint currentBlock = startingBlock;
        uint nextMouth;
        
        uint[100] memory keyTimes; // more than 100 hits is impossible with this configuration

        while(currentStateLength < INITIAL_SNAIL_LENGTH + iteration) {
            uint mouthBitmap = currentState[currentStateLength - 1];
            uint tail = currentState[currentStateLength - points - INITIAL_SNAIL_LENGTH];
            nextMouth = getNextAIMove(currentStateBitmap, mouthBitmap, apples[points], tail);
            currentStateBitmap = currentStateBitmap ^ tail;

            if(isCollision(nextMouth, currentStateBitmap)) {
                break;
            }

            currentState[currentStateLength] = nextMouth;
            currentStateLength++;

            currentStateBitmap = currentStateBitmap | nextMouth;
            if(currentStateBitmap & apples[points] > 0) {
                keyTimes[points] = currentStateLength - 1;
                points = points + 1;
                currentStateBitmap = currentStateBitmap | tail;
                apples[points] = getNewApple(currentBlock, currentStateBitmap, currentStateLength);
            }

            currentBlock = currentBlock + SPEED;
        }
        
        return (points, currentStateLength, keyTimes);
    }

    // ---- Drawing logic -----

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getAnimationPathOpt(uint[600] memory states, uint iterations) internal pure returns (bytes memory _path) {

        uint[2] memory firstPosition = decodePosition(states[0]);
        bytes memory path = abi.encodePacked(pathTemplate1, uint2str(firstPosition[1]), " ", uint2str(firstPosition[0]), " ");
        
        for(uint i = 0; i < iterations; i++) {
            uint[2] memory position = decodePosition(states[i]);
            path = abi.encodePacked(path, uint2str(position[1]), " ", uint2str(position[0]), " ");
        }

        return abi.encodePacked(path, pathTemplate2);
    }

    function getApples(uint[100] memory apples, uint[100] memory keyTimes, uint hits) internal pure returns (bytes memory _apples) {
        bytes memory appleElements;
    
        uint previousKeyTime = 0;
        for(uint i = 0; i <= hits; i++) {
            uint[2] memory position = decodePosition(apples[i]); 
            if(i == hits) {
                appleElements = abi.encodePacked(appleElements, appleTemplate1, uint2str(position[1]), appleTemplate2, uint2str(position[0]), appleTemplate3, strDiv(previousKeyTime, 4), appleTemplate4alt);
            }
            else {
                uint keyTime = keyTimes[i];
                appleElements = abi.encodePacked(appleElements, appleTemplate1, uint2str(position[1]), appleTemplate2, uint2str(position[0]), appleTemplate3, strDiv(previousKeyTime, 4), appleTemplate4, strDiv(keyTime, 4), appleTemplate5);
                previousKeyTime = keyTime;
            }
        }

        return appleElements;
    }

    function strDiv(uint i, uint div) internal pure returns (bytes memory _result) {
        return abi.encodePacked(uint2str(i * 1000 / div / 1000), ".", uint2str(i * 1000 / div % 1000));
    }

    function getTimesElements(uint t, uint[100] memory keyTimes, uint initialSnaleLength, uint speed) public pure returns (bytes memory _animationBegin, bytes memory _opacityBegin) {
        bytes memory animationBegin = strDiv(t + initialSnaleLength, speed); //abi.encodePacked(uint2str((t + initialSnaleLength) / 2 ), ".", uint2str((t + initialSnaleLength) * 10 / 2 % 10));
        bytes memory opacityBegin = strDiv(keyTimes[t], speed);

        return (animationBegin, opacityBegin);
    }


    function getStaticPixels(uint[600] memory states, uint iterations, uint snailLength) internal pure returns (bytes memory _pixels) {
        bytes memory pixels;
        uint[2] memory position;
        for(uint i = iterations - snailLength; i < iterations - 1; i++) {
            position = decodePosition(states[i]); 
            pixels = abi.encodePacked(pixels, pixelTemplateStatic1, uint2str(position[1]), pixelTemplateStatic2, uint2str(position[0]), pixelTemplateStatic3);
        }
        position = decodePosition(states[iterations - 1]); 
        pixels = abi.encodePacked(pixels, pixelTemplateStatic1Head, uint2str(position[1]), pixelTemplateStatic2, uint2str(position[0]), pixelTemplateStatic3);

        return pixels;
    }

    function getApplePixel(uint applePixel) internal pure returns (bytes memory _pixel) {
        uint[2] memory position = decodePosition(applePixel); 
        return abi.encodePacked(applePixelTemplateStatic1, uint2str(position[1]), pixelTemplateStatic2, uint2str(position[0]), pixelTemplateStatic3);
    }
    

    function getNumbers(uint points) internal pure returns (string memory _left, string memory _right) {
        return (getLeftNumber(points / 10), getRightNumber(points % 10));
    }


    function getAnimationElementNumbers(bool last, string memory number, bytes memory previousTimeStr, bytes memory keyTimeStr) internal pure returns (bytes memory _pixels) {

        if (!last) {
            return abi.encodePacked(
                        numbersTemplate1,
                        number, 
                        animatedNumberTemplate1, 
                        previousTimeStr, 
                        animatedNumberTemplate2, 
                        keyTimeStr,
                        animatedNumberTemplate3
                    );
        } else {
            return abi.encodePacked(
                    numbersTemplate1,
                    number, 
                    animatedNumberTemplate1, 
                    previousTimeStr, 
                    animatedNumberTemplate2alt
            );
        }
    }

    function getAnimatedLeftPointPixels(uint[100] memory keyTimes, uint points, uint speed) internal pure returns (bytes memory _pixels) {
        bytes memory numberElements;
        
        bytes memory previousKeyTimeStr = "0";

        string memory leftNumber;
        for(uint i = 9; i < points; i = i + 10) {
            leftNumber = getLeftNumber(i / 10);
            
            uint keyTime = keyTimes[i];
            bytes memory keyTimeStr = strDiv(keyTime, speed);
            numberElements = abi.encodePacked(numberElements, getAnimationElementNumbers(false, leftNumber, previousKeyTimeStr, keyTimeStr));
            previousKeyTimeStr = keyTimeStr;
        }

        leftNumber = getLeftNumber(points / 10);
        numberElements = abi.encodePacked(numberElements, getAnimationElementNumbers(true, leftNumber, previousKeyTimeStr, ""));

        return numberElements;
    }

    function getAnimatedRightPointPixels(uint[100] memory keyTimes, uint points, uint speed) internal pure returns (bytes memory _pixels) {
        bytes memory numberElements;
        
        bytes memory previousKeyTimeStr = "0";

        string memory rightNumber;
        for(uint i = 0; i < points; i++) {
            rightNumber = getRightNumber(i % 10);
            uint keyTime = keyTimes[i];
            bytes memory keyTimeStr = strDiv(keyTime, speed);
            numberElements = abi.encodePacked(numberElements, getAnimationElementNumbers(false, rightNumber, previousKeyTimeStr, keyTimeStr));
            previousKeyTimeStr = keyTimeStr;
        }

        rightNumber = getRightNumber(points % 10);
        numberElements = abi.encodePacked(numberElements, getAnimationElementNumbers(true, rightNumber, previousKeyTimeStr, ""));
            

        return numberElements;
    }

    function getPointPixels(uint points) internal pure returns (bytes memory _pixels) {
        uint left = points / 10;
        uint right = points % 10;

        return abi.encodePacked(numbersTemplate1, getLeftNumber(left), numbersTemplate2, numbersTemplate1, getRightNumber(right), numbersTemplate2);
    }

    function stateToImage(uint[600] memory states, uint[100] memory apples, uint iterations, uint points) internal pure returns (string memory _svg) {
        return string(abi.encodePacked(
            svgWrapper1,
            getApplePixel(apples[points]),
            getStaticPixels(states, iterations, points + INITIAL_SNAIL_LENGTH),
            getPointPixels(points),
            svgWrapper2));
    }
    
    function stateToGif(uint[600] memory states, uint[100] memory keyTimes, uint points, uint iterations, uint[100] memory apples) internal pure returns (string memory svg) {
        bytes memory duration = strDiv(iterations, 4);

        bytes memory gif = abi.encodePacked(
            svgWrapper1,
            getApples(apples, keyTimes, points),
            getAnimationPathOpt(states, iterations),
            getAnimatedLeftPointPixels(keyTimes, points, 4),
            getAnimatedRightPointPixels(keyTimes, points, 4),
            blinkingAnimationTemplate1,
            duration,
            blinkingAnimationTemplate2,
            pixelTemplate0a, strDiv(iterations, 4), pixelTemplate0b);

        
        gif = abi.encodePacked(gif, pixelTemplate1Head, "0", pixelTemplate2, duration, pixelTemplate3, "0", pixelTemplate4);
        gif = abi.encodePacked(gif, pixelTemplate1, "0.25", pixelTemplate2, duration, pixelTemplate3, "0.25", pixelTemplate4);
        gif = abi.encodePacked(gif, pixelTemplate1, "0.5", pixelTemplate2, duration, pixelTemplate3, "0.5", pixelTemplate4);

        bytes memory pixels;
        for(uint t = 0; t < points; t++) {
            (bytes memory animationBegin, bytes memory opacityBegin) = getTimesElements(t, keyTimes, INITIAL_SNAIL_LENGTH, 4);
            pixels = abi.encodePacked(pixels, pixelTemplate1, animationBegin, pixelTemplate2, duration, pixelTemplate3, opacityBegin, pixelTemplate4);
        }

        return string(
            abi.encodePacked(gif, pixels, svgWrapper2)
        );
    } 

    function getSVG(uint startingBlock, uint blockHash, uint randomness) internal view returns (string memory _svg, uint _points, uint _length, bool _gameOver) {
        uint iteration = calculateIterations(startingBlock, SPEED);
        (uint[600] memory initialStates, uint[100] memory initialApples, uint initialStateBitmap) = gameConfiguration(startingBlock, blockHash, randomness);
        
        (uint points, uint stateLength, uint[100] memory keyTimes) = getCurrentState(iteration, startingBlock, initialStates, initialStateBitmap, initialApples);
        string memory image;
        bool gameOver = isGameOver(stateLength, iteration);
        if(gameOver) {
            image = stateToGif(initialStates, keyTimes, points, stateLength, initialApples);
        }
        else {
            image = stateToImage(initialStates, initialApples, stateLength, points);
        }

        return (image, points, stateLength, gameOver);
    }


    function calculateIterations(uint startingBlock, uint speed) internal view returns (uint _iterations) {
        uint currentBlock = block.number;
        uint iterations = (currentBlock - startingBlock) / speed;

        return iterations;
    }

    // ------ Utlities -----
    function isGameOver(uint stateLength, uint iterations) internal pure returns (bool _over) {
        return stateLength < iterations + INITIAL_SNAIL_LENGTH;
    }


    function getConfig(uint tokenId) internal view returns (uint blockHash, uint randomness, uint startingBlock) {
        return (tokenIdToBlockHash[tokenId], tokenIdToRandomness[tokenId], tokenIdToStartingBlock[tokenId]);
    }

    function getAttributeString(bool gameOver, uint startingBlock, uint points, uint length) internal pure returns (bytes memory) {
        bytes memory attributeCommon = '{"trait_type":"';
        bytes memory blockAttribute = abi.encodePacked(attributeCommon, 'Start Block","value":"', uint2str(startingBlock), '"}');
        bytes memory pointsAttribute = abi.encodePacked(attributeCommon, 'Score","value":', uint2str(points), '}');
        bytes memory lengthAttribute = abi.encodePacked(attributeCommon, 'Moves","value":', uint2str(length - INITIAL_SNAIL_LENGTH), '}');
        string memory state = gameOver ? "Game Over" : "Playing";
        bytes memory gameOverAttribute = abi.encodePacked('{"trait_type": "State","value":"', state, '"}');

        return abi.encodePacked('"attributes":[',pointsAttribute,',',lengthAttribute,',',gameOverAttribute,',',blockAttribute,']');
    }


    // ------ IArcadeBackend implementation ------

    function tokenURI(uint tokenId) override external view onlyController returns (string memory) {
        (uint blockHash, uint randomness, uint startingBlock) = getConfig(tokenId);

        (string memory image, uint points, uint length, bool gameOver) = getSVG(startingBlock, blockHash, randomness);

        bytes memory attributeString = getAttributeString(gameOver, startingBlock, points, length);
        bytes memory json = abi.encodePacked('{"name":"ArcadeGlyph #', uint2str(tokenId), '","description":"",', attributeString,',"created_by":"Inner Space and Captain Pixel","image":"', image,'"}');
        
        return string(abi.encodePacked('data:text/plain,',json));

    }

    function insertCoin(uint tokenId, uint blockNumber) override external onlyController {
        tokenIdToBlockHash[tokenId] = uint(blockhash(blockNumber - 1));
        tokenIdToRandomness[tokenId] = (block.timestamp) * tokenId;
        tokenIdToStartingBlock[tokenId] = blockNumber;
    }

    function verifyPoints(uint minPoints, uint maxPoints, uint tokenId) override external view onlyController {
        (uint blockHash, uint randomness, uint startingBlock) = getConfig(tokenId);

        uint iteration = calculateIterations(startingBlock, SPEED);
        
        (uint[600] memory initialState, uint[100] memory initialApples, uint initialStateBitmap) = gameConfiguration(startingBlock, blockHash, randomness);
        
        (uint actualPoints, uint stateLength, ) = getCurrentState(iteration, startingBlock, initialState, initialStateBitmap, initialApples);
        

        require(isGameOver(stateLength, iteration), "Not over.");
        require(actualPoints >= minPoints, "Points too low");

        if(maxPoints >= minPoints) {
            require(actualPoints <= maxPoints, "Points too high");
        }
    }
}

// SPDX-License-Identifier: CC-BY-4.0

pragma solidity >= 0.8.0;

abstract contract IArcadeBackend {
    function tokenURI(uint tokenId) virtual external view returns (string memory);
    function verifyPoints(uint minPoints, uint maxPoints, uint tokenId) virtual external view;
    function insertCoin(uint tokenId, uint variant) virtual external;
    
    function interact(uint tokenId, uint[6] memory intActions, string[6] memory stringActions) external {
    }

    function restart(uint tokenId) external {
    }
}