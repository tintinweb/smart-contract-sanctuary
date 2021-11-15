//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/*
 
 * source       https://github.com/mickys/zoom-next/
 * @name        Zoom Contract
 * @package     ZoomNext
 * @author      Micky Socaci <[email protected]>
 * @license     MIT

 Generic ABI Batch caller 

*/

contract Zoom2 {
    
    function combine(bytes memory inputData) public view returns (bytes memory, bytes memory, bytes memory) {

        // 0x00 - we use for scratch memory
        // 0x20 - not used
        // 0x40 - free memory pointer

        // holds call result pointer addresses that we use to load reference 
        // call addresses, and populate "resultAddresses" and "OutputBuffer"
        // 1st word: address address
        // 2nd word: uint256 length
        bytes memory internalAddresses; 
        
        // holds result "start" addresses and their length in output buffer
        bytes memory resultOffsets; 
        
        // binary continuous buffer containing the resulting call values
        bytes memory OutputBuffer;

        assembly {
            
            // [0-1] version
            // [2-3] number of calls

            // add 32 since input is treated as a variable
            let ptr := add( inputData, 32 )

            // get number of calls -> mul first byte by 256 and add the rest from byte 2
            let callnum := add(
                mul( byte( 0, mload( add( ptr, 2 ) ) ), 256),
                byte( 0, mload( add( ptr, 3 ) ) )
            )

            // move free memory pointer
            mstore(0x40, msize()) 
            
            // move and resize internalAddresses in new memory
            internalAddresses := mload(0x40)

            // store length in first 32 bytes
            mstore(
                internalAddresses,
                // 64 bytes for each result.. 32 address / 32 length
                mul( callnum, 64 )
            ) 
    
            // allocate free space for internalAddresses
            for { let n := 0 } lt(n, mul(callnum, 2)) { n := add(n, 1) } {
                mstore( 
                    add ( 
                        add (internalAddresses, 32), // offset by 32 ( len )
                        mul( n, 32) 
                    ),
                    0
                )
            }

            // move free memory pointer
            mstore(0x40, msize()) 

            // move and resize resultOffsets in new memory
            resultOffsets := mload(0x40)

            // store length in first 32 bytes
            mstore(
                resultOffsets,
                // 32 bytes for each result.. as we want to be able to just mstore / mload
                mul( callnum, 32 )
            ) 
    
            // allocate free space for resultOffsets starting in data address space
            for { let n := 0 } lt(n, callnum) { n := add(n, 1) } {
                mstore( 
                    add ( 
                        add (resultOffsets, 32), // offset by 32 ( len )
                        mul( n, 32) 
                    ),
                    0
                )
            }

            // shift pointer to call start
            ptr := add( ptr, 6 )

            // move free memory pointer
            mstore(0x40, msize()) 
            
            // move OutputBuffer to free memory space
            OutputBuffer := add( mload(0x40), 32)

            // save length so we can set it in OutputBuffer
            let actualResultLength := 0

            // set write pointer 
            let thisOutputPointer := add( OutputBuffer, 32)
            
            let internalCounter := 0
            // let isExtCall := true

            // process calls 
            for { let callNumber := 0 } lt(callNumber, callnum) { callNumber := add(callNumber, 1) } {

                // get call data length in bytes [1-2]
                let dataLength := add(
                    mul( byte( 0, mload( add( ptr, 1 ) ) ), 256),
                    byte( 0, mload( add( ptr, 2 ) ) )
                )

                // clean up 0-32 byte scratch area so we can store a new address
                mstore( 0x00 , 0x0000000000000000000000000000000000000000000000000000000000000000 )
                
                let callType := byte( 0, mload( ptr ) )

                if eq(callType, 3) {
                    // reset internal counter so we can retrieve results from a different mapping
                    internalCounter := 0
                }

                if or( eq(callType, 2), eq(callType, 4)) {
                    
                    {

                        // read result_id where the "to address" is expected ( bytes[3-4] )
                        let result_id := add(
                            mul( byte( 0, mload( add( ptr, 3 ) ) ), 256),
                            byte( 0, mload( add( ptr, 4 ) ) )
                        )
                    
                        // read offset for the result ( bytes[5-6] )
                        let offset := add(
                            mul( byte( 0, mload( add( ptr, 5 ) ) ), 256),
                            byte( 0, mload( add( ptr, 6 ) ) )
                        )
                        
                        if eq(callType, 2) {

                            // find our result's address space
                            let resultStartAddress := add(
                                // shift pointer by 32 bytes, to data space
                                add(internalAddresses, 32),
                                // now multiply by 2 words ( record size )
                                mul( result_id, 64)
                            )

                            // load the contract address we're going to "call"
                            mstore (0x00, 
                                and( 
                                    // load 32 bytes, 12 garbage + 20 address
                                    mload( 
                                        sub( 
                                            add( 
                                                mload(resultStartAddress), 
                                            offset),
                                        12) 
                                    ),
                                    // 20 byte address "bytemask"
                                    sub( exp(256, 20), 1 )
                                )
                            )

                            // shift pointer by 8 bytes, to call data space
                            ptr := add( ptr, 8 )
                        }

                        if eq(callType, 4) {

                            let resultValue := mload(
                                                    mload(
                                                        add(
                                                            add(internalAddresses, 32),
                                                            mul( result_id, 64)
                                                        )
                                                    )
                                                )
                            
                            let callValue := resultValue

                            if or( gt(resultValue, internalCounter), eq(resultValue, internalCounter) ) {
                                callValue := sub(resultValue, internalCounter)
                                // increment internal counter
                                internalCounter := add(internalCounter, 1)
                            }

                            if gt(internalCounter, resultValue ) {
                                 callValue := 0
                            }

                            // replace call data id with computed value
                            mstore(add(ptr, 32), callValue)
                        }
                    }
                }

                if eq( eq(callType, 2), 0) {
                

                    // type 1 contains address in the next 20 bytes bytes [8-28]
                    // shift pointer by 8 bytes, to address space
                    ptr := add( ptr, 8 )

                    // load the contract address we're going to "call"
                    mstore (0x00, 
                        and( 
                            // load 32 bytes, 12 garbage + 20 address
                            mload( 
                                sub(ptr, 12) 
                            ),
                            // 20 byte address "bytemask"
                            sub( exp(256, 20), 1 )
                        )
                    )
                    
                    // shift pointer by 20 bytes, to call data space
                    ptr := add( ptr, 20 )

                }


                // finally load our address into a stack variable that our call can use
                let toAddress := mload( 0x00 )

                // do the call!
                {
                    let returnSize := 0
                    // type 3 is internal
                    // if eq(isExtCall, true) {

                        pop(
                            staticcall(      
                                500000,     
                                toAddress ,     // To addr
                                ptr,            // Inputs are stored at current ptr location
                                dataLength,     // input length
                                0,          
                                0
                            )
                        )
            
                        // copy result byte size from return value ( ignore first 32 bytes ) ( next 32 bytes )
                        returndatacopy( 
                            thisOutputPointer,
                            0, 
                            returndatasize() 
                        )
                        returnSize := returndatasize() 
                    // } 

                    // save result address in, so we can easily reference it
                    mstore( 
                        add(
                            add( internalAddresses, 32),
                            mul( callNumber, 64)
                        ),
                        thisOutputPointer
                    )

                    // save result length so we know how many bytes to read when
                    // preparing return OutputBuffer
                    mstore( 
                        add(
                            add( internalAddresses, 64), // add 32 so we're in the result space
                            mul( callNumber, 64)
                        ),
                        returnSize
                    )
                    
                    // shift pointer by data length.. so we're at next call
                    ptr := add( ptr, dataLength )

                    // move write pointer 
                    thisOutputPointer := add(thisOutputPointer, returnSize )
                    
                    actualResultLength := add( actualResultLength, returnSize )

                    // store result start offset
                    mstore( 
                        add ( 
                            add(resultOffsets, 32), // offset by 32 bytes to data space
                            mul(callNumber, 32) 
                        ),
                        sub( actualResultLength, returnSize )
                    )
                }

            }
            
            // set result length for OutputBuffer
            mstore(OutputBuffer, actualResultLength ) 

            // move free memory pointer so return does not overwrite our OutputBuffer
            // msize() breaks here for some reason.. so we move free memory space
            // address by hand using the write pointer.
            mstore(0x40, add( thisOutputPointer, 32 ) )
        }
        
        return ( OutputBuffer, resultOffsets, inputData );
    }
}

