// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "../interfaces/IYokaiHeroesDescriptor.sol";

/// @title Describes Yokai
/// @notice Produces a string containing the data URI for a JSON metadata string
contract YokaiSoullyThreeDescriptor is IYokaiHeroesDescriptor {

    /// @inheritdoc IYokaiHeroesDescriptor
    function tokenURI() external view override returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage()));
        string memory name = 'Soully Yokai #3';
        string memory description = generateDescription();

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() private pure returns (string memory){
        return '<svg id="Soully Yokai" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="420" height="420" viewBox="0 0 420 420"> <g id="background"><g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient><path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#000" stroke="#000" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g></g></g> <g id="Body"> <g id="Yokai"> <path id="Neck" d="M176,277.2c.8,10,1.1,20.2-.7,30.4a9.46,9.46,0,0,1-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2-8.1,2.3-9.5,12.4-2.1,16.4,71.9,38.5,146.3,42.5,224.4,7,7.2-3.3,7.3-12.7.1-16-22.3-10.3-43.5-23.1-54.9-29.9a10.93,10.93,0,0,1-5.1-8.3,126.62,126.62,0,0,1-.1-22.2,161,161,0,0,1,4.6-29.3" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ombre" d="M178.3,279.4s24.2,35,41,30.6S261,288.4,261,288.4c1.2-9.1,1.9-17.1,3.7-26-4.8,4.9-10.4,9.2-18.8,14.5a109.19,109.19,0,0,1-29.8,13.3Z" fill="#7099ae" fill-rule="evenodd"/> <path id="Head" d="M314.1,169.2c-.6-.8-12.2,8.3-12.2,8.3.3-4.9,11.8-53.1-17.3-86-15.9-17.4-42.2-27.1-69.9-27.7-24.5-.5-48.7,10.9-61.6,24.4-33.5,35-20.1,98.2-20.1,98.2.6,10.9,9.1,63.4,21.3,74.6,0,0,33.7,25.7,42.4,30.6a22.71,22.71,0,0,0,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l.2-.2c6.9-9.1,3.9-5.8,11.2-14.8a4.71,4.71,0,0,1,4.8-1.8c4.1.8,11.7,1.3,13.3-7,2.4-11.5,2.6-25.1,8.6-35.5C311.9,191.2,316.1,185,314.1,169.2Z" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ear" d="M142.1,236.4c.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48C116,164.1,132,183,132,183" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <g id="Ear2"> <path d="M304.4,175.6a10.14,10.14,0,0,1-2.3,3.5c-.9.8-1.7,1.4-2.6,2.2-1.8,1.7-3.9,3.2-5.5,5.2a53.07,53.07,0,0,0-4.2,6.3c-.6,1-1.3,2.2-1.9,3.3l-1.7,3.4-.2-.1,1.4-3.6c.5-1.1.9-2.4,1.5-3.5a56.34,56.34,0,0,1,3.8-6.8,23.83,23.83,0,0,1,5.1-5.9,22,22,0,0,1,3.2-2.1,12.65,12.65,0,0,0,3.1-2Z"/> </g> <g id="Buste"> <path d="M222.4,340.1c4.6-.4,9.3-.6,13.9-.9l14-.6c4.7-.1,9.3-.3,14-.4l7-.1h7c-2.3.2-4.6.3-7,.5l-7,.4-14,.6c-4.7.1-9.3.3-14,.4C231.8,340.1,227.1,340.2,222.4,340.1Z" fill="#2b232b"/> <path d="M142.5,337.6c4.3,0,8.4.1,12.6.2s8.4.3,12.6.5,8.4.4,12.6.7l6.4.4c2.1.2,4.2.3,6.4.5-2.1,0-4.2,0-6.4-.1l-6.4-.2c-4.2-.1-8.4-.3-12.6-.5s-8.4-.4-12.6-.7C151,338.4,146.9,338,142.5,337.6Z" fill="#2b232b"/> <path d="M199.5,329.6l1.6,3c.5,1,1,2,1.6,3a16.09,16.09,0,0,0,1.7,2.8c.2.2.3.4.5.6s.3.2.3.2a3.1,3.1,0,0,0,1.3-.6c1.8-1.3,3.4-2.8,5.1-4.3.8-.7,1.7-1.6,2.5-2.3l2.5-2.3a53.67,53.67,0,0,1-4.4,5.1,27.94,27.94,0,0,1-5.1,4.6,1.61,1.61,0,0,1-.7.4,1.69,1.69,0,0,1-1,.3,1.85,1.85,0,0,1-.7-.2c-.1-.1-.3-.2-.4-.3s-.4-.5-.6-.7c-.6-.9-1.1-2-1.7-3A55,55,0,0,1,199.5,329.6Z" fill="#2b232b"/> <path d="M199.5,329.6s3.5,9.3,5.3,10.1,11.6-10,11.6-10C210.1,331.3,204.2,331.5,199.5,329.6Z" fill-rule="evenodd" opacity="0.19" style="isolation: isolate"/> </g> </g> <g> <line x1="128.5" y1="179.3" x2="134.3" y2="186.7" fill="none"/> <path d="M128.5,179.3a11,11,0,0,1,5.7,7.4A11.58,11.58,0,0,1,128.5,179.3Z"/> </g> </g> <g id="Marks" > <g id="Blood_Akuma"> <g id="Eye" > <path d="M237.8,224.4c0-3.6,2.6-85.2,2.8-88.9s-1.8-24.7-1.6-28.3c5.6-6.5,11.4-32.8,15.3-33-4.5,2.4-7.7,29.2-10.9,33l-.2,31.1c.1,4.7-2.5,81.1-2.2,86.2a17.68,17.68,0,0,0-1.6,2.2A18.82,18.82,0,0,0,237.8,224.4Z" fill="#60d5dc"/> </g> <g id="Eye"> <path d="M163.5,223.8c-.1-3.6.1-88.4.2-92s1.8-21.8,2-25.4c5.5-6.6,13.9-34.7,18.4-34.6-5.3,2-11.8,33-14.9,37l-2.8,25.6c.2,3.6,0,85.7.3,89.3l-1.7,3.1Z" fill="#52d784"/> </g> </g> </g> <g id="Nose" > <g id="Akuma" > <path d="M191.8,224.9c6.1,1,12.2,1.7,19.8.4l-8.9,6.8a1.5,1.5,0,0,1-1.8,0Z" fill="#22608a" stroke="#22608a" stroke-miterlimit="10" opacity="0.5" style="isolation: isolate"/> <path d="M196.6,229.6c-.4.3-2.1-.9-4.1-2.5s-3-2.7-2.6-2.9,2.5,0,4.2,1.8C195.6,227.6,197,229.2,196.6,229.6Z" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M206.7,229.1c.3.4,2.2-.3,4.2-1.7s3.5-2,3.2-2.4-2.5-.7-4.5.7C207.6,227.3,206.3,228.6,206.7,229.1Z" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> <g id="Eyes"> <g id="Pupils"> <g> <g id="No_Fill"> <g> <path d="M219.3,197.7s3.1-22.5,37.9-15.5C257.3,182.1,261.2,209.2,219.3,197.7Z" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M227.5,182.5a13.5,13.5,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3a25.25,25.25,0,0,0-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6a11.94,11.94,0,0,1,.8-1.6,17.57,17.57,0,0,1,4.7-5.1A4.82,4.82,0,0,1,227.5,182.5Z" fill="#2f3555"/> <path d="M245.6,201.3a14.79,14.79,0,0,0,3.6-1,20.16,20.16,0,0,0,3.2-1.8,16,16,0,0,0,2.7-2.5c.8-1,1.6-2,2.3-3a7.65,7.65,0,0,1-1.7,3.5,12.4,12.4,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.6,201.3Z" fill="#2f3555"/> </g> <g> <path d="M184.1,197.7s-3.1-22.5-37.9-15.5C146.2,182.1,142.2,209.2,184.1,197.7Z" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M176,182.5a13.5,13.5,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3a25.25,25.25,0,0,1,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6a11.94,11.94,0,0,0-.8-1.6,17.57,17.57,0,0,0-4.7-5.1A5.45,5.45,0,0,0,176,182.5Z" fill="#2f3555"/> <path d="M157.8,201.3a14.79,14.79,0,0,1-3.6-1,20.16,20.16,0,0,1-3.2-1.8,16,16,0,0,1-2.7-2.5c-.8-1-1.6-2-2.3-3a7.65,7.65,0,0,0,1.7,3.5,12.4,12.4,0,0,0,2.8,2.8A11.37,11.37,0,0,0,154,201,8.1,8.1,0,0,0,157.8,201.3Z" fill="#2f3555"/> </g> </g> <g id="Shadow" opacity="0.43"> <path d="M218.5,192s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C219.1,184.2,218.5,192,218.5,192Z" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow-2" opacity="0.43"> <path d="M185.1,191.7s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.6,184,185.1,191.7,185.1,191.7Z" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> </g> </g> <g id="Akuma"> <path d="M246.7,192.4h-13a1.24,1.24,0,0,1-1.3-1.2v-.1h0a1.24,1.24,0,0,1,1.2-1.3h13.1A1.24,1.24,0,0,1,248,191v.1h0A1.49,1.49,0,0,1,246.7,192.4Z" fill="#5fced6"/> <path d="M170.1,192.4h-13a1.24,1.24,0,0,1-1.3-1.2v-.1h0a1.24,1.24,0,0,1,1.2-1.3h13.1a1.24,1.24,0,0,1,1.3,1.2v.1h0A1.49,1.49,0,0,1,170.1,192.4Z" fill="#52d784"/> </g> </g> <g id="Mouth"> <g id="Evil"> <g> <path d="M177.5,251.3s16.5-1.1,17.8-1.6,35.2,6.6,37.2,5.7,4.7-2,4.7-2-14.4,8.3-44.5,8.2c0,0-4-.7-4.8-1.9C187,258.7,179.9,251.8,177.5,251.3Z" fill="#fff"/> <path d="M177.4,251.3a1.27,1.27,0,0,1,.6-.1l.6-.1,1.1-.1,2.2-.3,4.4-.5,4.4-.5,2.2-.3,1.1-.2c.4-.1.7-.1,1-.2h.1a1.39,1.39,0,0,1,.9,0l.7.1,1.3.2,2.7.4,5.3.9,10.5,2.1c3.5.7,7,1.4,10.5,1.9l2.6.3a11.33,11.33,0,0,0,2.6.1,1.42,1.42,0,0,0,.6-.2l.6-.3,1.2-.5,2.4-1.1.3.7a52.05,52.05,0,0,1-10.7,4.3,107,107,0,0,1-11.2,2.6l-2.8.5a27,27,0,0,0-2.8.4,54.81,54.81,0,0,1-5.7.5l-5.7.3h-5.8a19.73,19.73,0,0,1-2.6-.7c-.4-.2-.9-.3-1.3-.5a2.94,2.94,0,0,1-1.2-1v.1c-.7-.8-1.5-1.6-2.3-2.4s-1.6-1.6-2.4-2.3a26.22,26.22,0,0,0-2.5-2.2,6.42,6.42,0,0,0-1.3-1A5.07,5.07,0,0,0,177.4,251.3Zm.2,0a1.08,1.08,0,0,1,.8.2,2,2,0,0,1,.8.4c.5.3,1,.6,1.4.9.9.6,1.8,1.3,2.7,2s1.7,1.4,2.6,2.2,1.7,1.5,2.5,2.3v.1c.1.2.5.4.8.6a5.64,5.64,0,0,0,1.2.4c.8.2,1.6.4,2.5.6h-.1l5.7-.2c1.9-.1,3.8-.2,5.7-.4,3.8-.3,7.5-.7,11.3-1.3a109.43,109.43,0,0,0,11.1-2.3c1.8-.5,3.6-1,5.4-1.6a47.07,47.07,0,0,0,5.2-2.1l.3.7-2.5,1-1.2.5-.6.3a1.85,1.85,0,0,1-.7.2,12.29,12.29,0,0,1-2.7-.2,25.12,25.12,0,0,1-2.7-.4l-10.6-1.6c-3.5-.5-7.1-1-10.6-1.6l-5.3-.9-2.6-.4-1.3-.2-.6-.1h-.3a5,5,0,0,1-1.2.2l-1.1.1c-.7.1-1.5.1-2.2.2l-4.5.3c-1.5.1-3,.2-4.5.2l-2.2.1h-1.7C177.9,251.3,177.7,251.4,177.6,251.3Z"/> </g> <path d="M184.4,256.6a4.18,4.18,0,0,1,1.8-1.1c.3-.1.7-.1,1.1-.2a1.93,1.93,0,0,0,1-.3h.1a3.4,3.4,0,0,0,1,.1,3.55,3.55,0,0,1,1,.2,6.19,6.19,0,0,1,1.9.7H192c.4-.1.8-.2,1.3-.3v.1l-.9.9-.1.1h-.2a5.92,5.92,0,0,1-1.9-.5,3.55,3.55,0,0,1-.9-.4c-.3-.2-.6-.3-.9-.5h.1a4.18,4.18,0,0,0-1,.4l-.9.6a8.2,8.2,0,0,1-2.2.2Z"/> <path d="M201.5,256.9a25.75,25.75,0,0,1,4-.8,28.45,28.45,0,0,1,4.1-.4h.2c1.1.6,2.2,1.3,3.3,1.8H213c1.5-.5,2.9-1.2,4.3-1.7h.1l.2.1c1.1.4,2.1.8,3.1,1.2h-.2c1.5-.1,3-.2,4.5-.2s3,0,4.5.1v.1a33.21,33.21,0,0,1-4.4.6,32.53,32.53,0,0,1-4.4.3h-.2c-1-.5-2-.9-3.1-1.4h.3c-1.5.4-3,.8-4.5,1.3H213a21.3,21.3,0,0,0-3.5-1.4h.2a27.33,27.33,0,0,1-4,.5c-1.5,0-2.8,0-4.2-.1Z"/> </g> </g> <g id="Accessoire" > <g id="Small_Horn"> <g> <path d="M257.7,101.1s10.6-.7,16.6-12.7c0,0,6.3,10.6-5.2,25.1C263.6,110.7,259.6,106.5,257.7,101.1Z" fill="#bfd2d3" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M258.4,101.5A13.63,13.63,0,0,0,269,112.9" fill="#bfd2d3" stroke="#bfd2d3" stroke-miterlimit="10" fill-rule="evenodd"/> </g> <g> <path d="M159.6,102S149,101.3,143,89.3c0,0-6.3,10.6,5.2,25.1C153.6,111.6,157.7,107.4,159.6,102Z" fill="#bfd2d3" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M159.1,102.4c0,.1-1.5,9.4-10.7,11.3" fill="#bfd2d3" stroke="#bfd2d3" stroke-miterlimit="10" fill-rule="evenodd"/> </g> </g> </g> <g id="Ring"> <path d="M288.4,234.4s-4.4,2.1-3.2,6.4c1,4.3,4.4,4,4.8,4a3.94,3.94,0,0,0,3.9-4.2" fill="none" stroke="#60d5dc" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> <path d="M136.4,232.6s-4.4,2.1-3.2,6.4c1,4.3,4.5,3.8,4.8,3.6s1.6.2,3.4-2.3" fill="none" stroke="#52d784" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> </g> </svg>';
    }

    function generateDescription() private pure returns (string memory){
        return 'yokai\'chain x spiritswap';
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title Describes Yokai via URI
interface IYokaiHeroesDescriptor {
    /// @notice Produces the URI describing a particular Yokai (token id)
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI() external view returns (string memory);
}