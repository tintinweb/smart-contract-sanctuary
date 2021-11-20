// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "../interfaces/IYokaiHeroesDescriptor.sol";

/// @title Describes Yokai
/// @notice Produces a string containing the data URI for a JSON metadata string
contract YokaiSoullyOneDescriptor is IYokaiHeroesDescriptor {

    /// @inheritdoc IYokaiHeroesDescriptor
    function tokenURI() external view override returns (string memory) {
        string memory image = Base64.encode(bytes(generateSVGImage()));
        string memory name = 'Soully Yokai #1';
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
        return '<svg id="Soully Yokai" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="420" height="420" viewBox="0 0 420 420"> <g id="background"><g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient><path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#000" stroke="#000" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#000" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g></g></g> <g id="Body" > <g id="Yokai"> <path id="Neck" d="M175.8,276.8c.8,10,1.1,20.2-.7,30.4a9.31,9.31,0,0,1-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2-8.1,2.3-9.5,12.4-2.1,16.4,71.9,38.5,146.3,42.5,224.4,7,7.2-3.3,7.3-12.7.1-16-22.3-10.3-43.5-23.1-54.9-29.9a11.17,11.17,0,0,1-5.1-8.3,125.18,125.18,0,0,1-.1-22.2,164.09,164.09,0,0,1,4.6-29.3" transform="translate(-0.8 0.4)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <path id="Ombre" d="M178.1,279s24.2,35,41,30.6S260.8,288,260.8,288c1.2-9.1,1.9-17.1,3.7-26-4.8,4.9-10.4,9.2-18.8,14.5a108.88,108.88,0,0,1-29.8,13.3Z" transform="translate(-0.8 0.4)" fill="#7099ae" fill-rule="evenodd"/> <path id="Head" d="M313.9,170c-.6-.8-12.2,8.3-12.2,8.3.3-4.9,11.8-53.1-17.3-86-15.9-17.4-42.2-27.1-69.9-27.7C190,64.1,165.8,75.5,152.9,89c-33.5,35-20.1,98.2-20.1,98.2.6,10.9,9.1,63.4,21.3,74.6,0,0,33.7,25.7,42.4,30.6a22.85,22.85,0,0,0,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l.2-.2c6.9-9.1,3.9-5.8,11.2-14.8a4.85,4.85,0,0,1,4.8-1.8c4.1.8,11.7,1.3,13.3-7,2.4-11.5,2.6-25.1,8.6-35.5C311.7,192,315.9,185.8,313.9,170Z" transform="translate(-0.8 0.4)" fill="#bfd2d3" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3" fill-rule="evenodd"/> <g id="Ear"> <path d="M141.9,236c.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7" transform="translate(-0.8 0.4)" fill="#bfd2d3" fill-rule="evenodd"/> <path d="M141.9,236a.66.66,0,0,1-.4.5,4.88,4.88,0,0,1-.7.3,7.08,7.08,0,0,1-1.4.1,6.3,6.3,0,0,1-2.7-1,10.91,10.91,0,0,1-3.6-4.6,21.62,21.62,0,0,1-1.6-5.5c-.3-1.9-.5-3.7-.8-5.5-.6-3.6-1.4-7.2-2.3-10.8s-1.9-7.1-3-10.6-2.1-7.1-3.2-10.6-2.2-7.1-3.2-10.7c-.2-.9-.5-1.8-.7-2.8a7.77,7.77,0,0,1-.2-1.6,3.75,3.75,0,0,1,.1-1,1.91,1.91,0,0,1,.9-1.2,1.74,1.74,0,0,1,1.4-.1l.9.3a14.8,14.8,0,0,1,1.3.8,20,20,0,0,1,2.2,1.9,84.08,84.08,0,0,1,7.2,8.6c-2.7-2.6-5.3-5.2-8.2-7.5a17.68,17.68,0,0,0-2.2-1.6c-.4-.2-.7-.4-1.1-.6a.9.9,0,0,0-.5-.1h0l.1-.1v.4a5,5,0,0,0,.2,1.2c.2.8.5,1.7.8,2.6l3.6,10.5c1.2,3.5,2.3,7.1,3.4,10.6a125.61,125.61,0,0,1,4.7,21.9c.2,1.9.3,3.8.5,5.6a23.78,23.78,0,0,0,1.1,5.3,9.91,9.91,0,0,0,2.7,4.5,5.1,5.1,0,0,0,2.3,1.2,2.88,2.88,0,0,0,1.3.1c.2,0,.4-.1.7-.1C141.6,236.3,141.9,236.2,141.9,236Z" transform="translate(-0.8 0.4)"/> </g> <g id="Ear"> <path d="M305,175.7a10.65,10.65,0,0,1-2.3,3.5c-.9.8-1.7,1.4-2.6,2.2-1.8,1.7-3.9,3.2-5.5,5.2a53.07,53.07,0,0,0-4.2,6.3c-.6,1-1.3,2.2-1.9,3.3l-1.7,3.4-.2-.1,1.4-3.6c.5-1.1.9-2.4,1.5-3.5a50.9,50.9,0,0,1,3.8-6.8,22.4,22.4,0,0,1,5.1-5.9,29.22,29.22,0,0,1,3.2-2.1,12.65,12.65,0,0,0,3.1-2Z" transform="translate(-0.8 0.4)"/> </g> <g id="Buste"> <path d="M222.2,339.7c4.6-.4,9.3-.6,13.9-.9l14-.6c4.7-.1,9.3-.3,14-.4l7-.1h7c-2.3.2-4.6.3-7,.5l-7,.4-14,.6c-4.7.1-9.3.3-14,.4C231.6,339.7,226.9,339.8,222.2,339.7Z" transform="translate(-0.8 0.4)" fill="#2b232b"/> <path d="M142.3,337.2c4.3,0,8.4.1,12.6.2s8.4.3,12.6.5,8.4.4,12.6.7l6.4.4c2.1.2,4.2.3,6.4.5-2.1,0-4.2,0-6.4-.1l-6.4-.2c-4.2-.1-8.4-.3-12.6-.5s-8.4-.4-12.6-.7C150.8,338,146.7,337.6,142.3,337.2Z" transform="translate(-0.8 0.4)" fill="#2b232b"/> <path d="M199.3,329.2l1.6,3c.5,1,1,2,1.6,3a16.09,16.09,0,0,0,1.7,2.8c.2.2.3.4.5.6s.3.2.3.2a3.57,3.57,0,0,0,1.3-.6c1.8-1.3,3.4-2.8,5.1-4.3.8-.7,1.7-1.6,2.5-2.3l2.5-2.3a53.67,53.67,0,0,1-4.4,5.1,32.13,32.13,0,0,1-5.1,4.6,2.51,2.51,0,0,1-.7.4,2.37,2.37,0,0,1-1,.3,1.45,1.45,0,0,1-.7-.2c-.1-.1-.3-.2-.4-.3s-.4-.5-.6-.7c-.6-.9-1.1-2-1.7-3A59,59,0,0,1,199.3,329.2Z" transform="translate(-0.8 0.4)" fill="#2b232b"/> <path d="M199.3,329.2s3.5,9.3,5.3,10.1,11.6-10,11.6-10C209.9,330.9,204,331.1,199.3,329.2Z" transform="translate(-0.8 0.4)" fill-rule="evenodd" opacity="0.19" style="isolation: isolate"/> </g> </g> </g> <g id="Marks"> <g id="Tomoe"> <path d="M289,339.8h0a5,5,0,1,0,0,7.3l.4-.4v.1c2.7,1.9,3.6,5.8,3.6,5.8C293.9,343.3,289,339.8,289,339.8Zm-2.2,5a1.7,1.7,0,1,1,.1-2.4A1.72,1.72,0,0,1,286.8,344.8Z" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> <path d="M275.1,347.9h0a5,5,0,1,0-2.5,6.6c.1-.1.2-.1.4-.2,1.8,2.7,1.5,6.6,1.5,6.6C277.8,353.8,275.8,349.2,275.1,347.9Zm-3.9,3.5a1.62,1.62,0,0,1-2.2-.8,1.66,1.66,0,1,1,2.2.8Z" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> <path d="M136.6,339.1a5.08,5.08,0,0,0-6.9,0h0s-4.9,3.5-4,12.8c0,0,.9-3.9,3.6-5.8V346c.1.1.2.3.4.4a5,5,0,1,0,6.9-7.3Zm-2.2,4.9a2,2,0,0,1-2.4.1,1.7,1.7,0,1,1,2.4-.1Z" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> <path d="M150.5,344.6a5.14,5.14,0,0,0-6.7,2.5c0,.1-.1.1-.1.2-.7,1.4-2.5,6,.7,12.9,0,0-.3-3.9,1.5-6.6.1.1.2.1.4.2a5.06,5.06,0,0,0,4.2-9.2Zm-.7,5.3a1.66,1.66,0,1,1-.8-2.2A1.65,1.65,0,0,1,149.8,349.9Z" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> <path d="M226.6,355.4a5.13,5.13,0,0,0-6.4-2.9,5.06,5.06,0,0,0,3.5,9.5c.1-.1.3-.1.4-.2,1.6,2.9,1,6.8,1,6.8C229.4,360.9,227,356,226.6,355.4Zm-4,3.5a2,2,0,0,1-2.2-1,1.71,1.71,0,1,1,2.2,1Z" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> <path d="M190.2,351.9a4.94,4.94,0,0,0-6.5,2.5h0s-3.3,5,.8,13.4c0,0-.4-4,1.4-6.8h0a.76.76,0,0,0,.4.2,5,5,0,0,0,3.9-9.3Zm-.6,5.3c-.2,1-1.2,1.3-2.2.9a1.68,1.68,0,1,1,2.2-.9Z" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> </g> </g> <g id="Earrings"> <g id="Tomoe"> <path d="M289,234.7s-4.4,2.1-3.2,6.4a4.61,4.61,0,0,0,5.6,3.6c.3-.2,3.2-.9,3.1-5.2" transform="translate(-0.8 0.4)" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> <path d="M135.9,232.9s-4.4,2.1-3.2,6.4a4.61,4.61,0,0,0,5.6,3.6c.3-.1,3.3-.6,3.2-4.8" transform="translate(-0.8 0.4)" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> <g> <path d="M294.7,250.1s-2,5.6-11.3,7.4a11.88,11.88,0,0,0,4.6-5.2" transform="translate(-0.8 0.4)" fill-rule="evenodd"/> <path d="M294.6,250.4a5,5,0,1,0-6.9,1.8A5.14,5.14,0,0,0,294.6,250.4Zm-5.8-3.4a1.68,1.68,0,1,1,.6,2.3A1.64,1.64,0,0,1,288.8,247Z" transform="translate(-0.8 0.4)" fill-rule="evenodd"/> </g> <g> <path d="M131.8,247.3s.4,6,8.8,10.2a11.81,11.81,0,0,1-3-6.3" transform="translate(-0.8 0.4)" fill-rule="evenodd"/> <path d="M131.8,247.6a5,5,0,1,1,6.1,3.6A5,5,0,0,1,131.8,247.6Zm6.5-1.7A1.75,1.75,0,1,0,137,248,1.77,1.77,0,0,0,138.3,245.9Z" transform="translate(-0.8 0.4)" fill-rule="evenodd"/> </g> </g> <g id="Tomoe"> <path d="M289,234.7s-4.4,2.1-3.2,6.4a4.61,4.61,0,0,0,5.6,3.6c.3-.2,3.2-.9,3.1-5.2" transform="translate(-0.8 0.4)" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> <path d="M135.9,232.9s-4.4,2.1-3.2,6.4a4.61,4.61,0,0,0,5.6,3.6c.3-.1,3.3-.6,3.2-4.8" transform="translate(-0.8 0.4)" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/> <g> <path d="M294.7,250.1s-2,5.6-11.3,7.4a11.88,11.88,0,0,0,4.6-5.2" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> <path d="M294.6,250.4a5,5,0,1,0-6.9,1.8A5.14,5.14,0,0,0,294.6,250.4Zm-5.8-3.4a1.68,1.68,0,1,1,.6,2.3A1.64,1.64,0,0,1,288.8,247Z" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> </g> <g> <path d="M131.8,247.3s.4,6,8.8,10.2a11.81,11.81,0,0,1-3-6.3" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> <path d="M131.8,247.6a5,5,0,1,1,6.1,3.6A5,5,0,0,1,131.8,247.6Zm6.5-1.7A1.75,1.75,0,1,0,137,248,1.77,1.77,0,0,0,138.3,245.9Z" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> </g> </g> </g> <g id="Nose"> <g id="Akuma"> <path d="M191.6,224.5c6.1,1,12.2,1.7,19.8.4l-8.9,6.8a1.5,1.5,0,0,1-1.8,0Z" transform="translate(-0.8 0.4)" fill="#22608a" stroke="#22608a" stroke-miterlimit="10" opacity="0.5" style="isolation: isolate"/> <path d="M196.4,229.2c-.4.3-2.1-.9-4.1-2.5s-3-2.7-2.6-2.9,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2Z" transform="translate(-0.8 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M206.5,228.7c.3.4,2.2-.3,4.2-1.7s3.5-2,3.2-2.4-2.5-.7-4.5.7C207.4,226.9,206.1,228.2,206.5,228.7Z" transform="translate(-0.8 0.4)" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> </g> <g id="Eyebrow"> <g id="Tomoe"> <g> <path d="M220.6,167.5s5.6-4.1,15.1,1.1c0,0-4.5-.6-7.7,1.7" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> <path d="M220.8,167.3a6.18,6.18,0,0,0-3,8.1,5.32,5.32,0,0,0,7.4,3.3,6.18,6.18,0,0,0,3-8.1A5.6,5.6,0,0,0,220.8,167.3Zm2.9,7.7a1.87,1.87,0,0,1-2.5-1.1,2.2,2.2,0,0,1,1-2.7,1.87,1.87,0,0,1,2.5,1.1A2.14,2.14,0,0,1,223.7,175Z" transform="translate(-0.8 0.4)" fill="#60d5dc" fill-rule="evenodd"/> </g> <g> <path d="M182,167s-5.6-4.1-15.1,1.1c0,0,4.5-.6,7.7,1.7" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> <path d="M181.6,166.7a6.18,6.18,0,0,1,3,8.1,5.32,5.32,0,0,1-7.4,3.3,6.18,6.18,0,0,1-3-8.1C175.6,167,178.8,165.5,181.6,166.7Zm-2.7,7.8a1.87,1.87,0,0,0,2.5-1.1,2.2,2.2,0,0,0-1-2.7,1.87,1.87,0,0,0-2.5,1.1A2,2,0,0,0,178.9,174.5Z" transform="translate(-0.8 0.4)" fill="#52d784" fill-rule="evenodd"/> </g> </g> </g> <g id="Eyes"> <g id="Pupils_Kuro"> <g> <g id="No_Fill"> <g> <path d="M219.1,197.3s3.1-22.5,37.9-15.5C257.1,181.7,261,208.8,219.1,197.3Z" transform="translate(-0.8 0.4)" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M227.3,182.1a13.5,13.5,0,0,0-2.7,2c-.8.7-1.6,1.6-2.3,2.3s-1.5,1.7-2.1,2.5l-1,1.4c-.3.4-.6.9-1,1.4.2-.5.4-1,.6-1.6s.5-1,.8-1.6a17.2,17.2,0,0,1,4.7-5.1A4.88,4.88,0,0,1,227.3,182.1Z" transform="translate(-0.8 0.4)" fill="#2f3555"/> <path d="M245.4,200.9a13.64,13.64,0,0,0,3.6-1,14.53,14.53,0,0,0,3.2-1.8,16,16,0,0,0,2.7-2.5,34,34,0,0,0,2.3-3,7.65,7.65,0,0,1-1.7,3.5,10.65,10.65,0,0,1-2.8,2.8,11.37,11.37,0,0,1-3.5,1.7A7,7,0,0,1,245.4,200.9Z" transform="translate(-0.8 0.4)" fill="#2f3555"/> </g> <g> <path d="M183.9,197.3s-3.1-22.5-37.9-15.5C146,181.7,142,208.8,183.9,197.3Z" transform="translate(-0.8 0.4)" fill="#2f3555" stroke="#2f3555" stroke-miterlimit="10"/> <path d="M175.8,182.1a13.5,13.5,0,0,1,2.7,2c.8.7,1.6,1.6,2.3,2.3s1.5,1.7,2.1,2.5l1,1.4c.3.4.6.9,1,1.4-.2-.5-.4-1-.6-1.6s-.5-1-.8-1.6a17.2,17.2,0,0,0-4.7-5.1A5.15,5.15,0,0,0,175.8,182.1Z" transform="translate(-0.8 0.4)" fill="#2f3555"/> <path d="M157.6,200.9a13.64,13.64,0,0,1-3.6-1,14.53,14.53,0,0,1-3.2-1.8,16,16,0,0,1-2.7-2.5,34,34,0,0,1-2.3-3,7.65,7.65,0,0,0,1.7,3.5,10.65,10.65,0,0,0,2.8,2.8,11.37,11.37,0,0,0,3.5,1.7A7.14,7.14,0,0,0,157.6,200.9Z" transform="translate(-0.8 0.4)" fill="#2f3555"/> </g> </g> <g id="Shadow" opacity="0.43"> <path d="M218.3,191.6s4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8C218.9,183.8,218.3,191.6,218.3,191.6Z" transform="translate(-0.8 0.4)" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> <g id="Shadow-2" opacity="0.43"> <path d="M184.9,191.3s-4.8-10.6-20.1-13.4c0,0,12.4-.2,16.3,2.6C184.4,183.6,184.9,191.3,184.9,191.3Z" transform="translate(-0.8 0.4)" fill="#2f3555" opacity="0.5" style="isolation: isolate"/> </g> </g> <ellipse cx="238.3" cy="190.3" rx="5.7" ry="7.3" fill="#60d5dc"/> <ellipse cx="163.6" cy="190.6" rx="5.7" ry="7.3" fill="#52d784"/> </g> </g> <g id="Mouth"> <g id="Akuma"> <path d="M279.43,242.91c-8.1,1.5-19.53,4.39-27.73,5.69a183.37,183.37,0,0,1-24.6,2.8l.3-.2-5.6,10.9-.4.7-.4-.7-5.3-10.4.4.2c-4.8.3-9.6.6-14.4.5a116.32,116.32,0,0,1-14.4-1.1l.4-.2L182,262.4l-.3.5-.3-.5-5.9-11.6.2.1-7.6-.6a66.26,66.26,0,0,1-7.6-1.1c-1.3-.2-2.5-.5-3.8-.8s-2.5-.6-3.8-1c-2.4-.7-4.9-1.5-7.3-2.4v-.1c2.5.4,5,1,7.5,1.6,1.3.2,2.5.5,3.8.8l3.8.8c2.5.5,5,1.1,7.5,1.6a38.44,38.44,0,0,0,7.6.8h.1l.1.1,6.1,11.6h-.5l5.5-11.3.1-.2h.3a137.42,137.42,0,0,0,14.3,1c4.8,0,9.6-.2,14.4-.5h.3l.1.2,5.3,10.4h-.7l5.7-10.8.1-.2h.2a183.41,183.41,0,0,0,24.5-2.6c8-1.1,18.9-3.18,27-4.48Z" transform="translate(-0.8 0.4)"/> </g> </g> <g id="Accessoire" > <g id="Bloody" > <g> <path d="M255.6,94.5s36.9-18,49.2-42.8c0,0-1.8,38.5-25.6,68.6C267.8,114.5,259.6,105.9,255.6,94.5Z" transform="translate(-0.8 0.4)" fill="#1dc7f0" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M256.7,94.8c-.1.2,4.3,18.1,22.8,24.4" transform="translate(-0.8 0.4)" fill="none" stroke="#1dc7f0" stroke-miterlimit="10" stroke-width="2"/> </g> <g> <path d="M160.5,94s-36.9-18.1-49.2-43c0,0,1.8,38.6,25.6,68.9C148.3,114.1,156.5,105.4,160.5,94Z" transform="translate(-0.8 0.4)" fill="#1dc7f0" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M159.7,94.1c.1.2-5.1,19-22.9,24.5" transform="translate(-0.8 0.4)" fill="none" stroke="#1dc7f0" stroke-miterlimit="10" stroke-width="2"/> </g> </g> <g id="Horn" > <g> <path d="M255.6,94.5s36.9-18,49.2-42.8c0,0-1.8,38.5-25.6,68.6C267.8,114.5,259.6,105.9,255.6,94.5Z" transform="translate(-0.8 0.4)" fill="#bfd2d3" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M256.7,94.8c-.1.2,4.3,18.1,22.8,24.4" transform="translate(-0.8 0.4)" fill="none" stroke="#bfd2d3" stroke-miterlimit="10" stroke-width="2"/> </g> <g> <path d="M160.5,94s-36.9-18.1-49.2-43c0,0,1.8,38.6,25.6,68.9C148.3,114.1,156.5,105.4,160.5,94Z" transform="translate(-0.8 0.4)" fill="#bfd2d3" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M159.7,94.1c.1.2-5.1,19-22.9,24.5" transform="translate(-0.8 0.4)" fill="none" stroke="#bfd2d3" stroke-miterlimit="10" stroke-width="2"/> </g> </g> </g> </svg>';
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