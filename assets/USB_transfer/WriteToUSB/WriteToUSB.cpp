// WriteToUSB.cpp : Defines the entry point for the console application.

#include "WriteToUSB.h"

//our main loop
int _tmain(int argc, _TCHAR* argv[])
{
	printf("****************\n");
	printf("*USB Read/Write*\n");
	printf("****************\n\n");

	char input[100];
	while(1){
		printf("\nMAIN MENU\n\n");
		printf("   [L]oad .bit to USB\n");
		printf("   [H]and enter bytes to send to USB\n");
		printf("   [Q]uit\n\n");
		scanf_s("%s", &input, 100);
		if(strcmp(input,"L") == 0)
			LoadBitfile();
		else if(strcmp(input,"H") == 0)
			HandEnterBytes();
		else if(strcmp(input,"Q") == 0)
			break;
		else
			printf("Unrecognized Input (Must be capitalized)\n");
	}
	return 0;
}

//Attempts to open a file, and sends it on success
void LoadBitfile(){
	FILE* file;
	char input[100];

	while(1){
		printf("\nLOAD BIT FILE\n\n");
		printf("   [C]ancel\n");
		printf("   (anything else to load)\n");
		printf("    Filename To Read (INCLUDE extension): ");
		scanf_s("%s", &input, 100);
		if(strcmp(input,"C")==0)
			return;
		else{
			if(fopen_s(&file,input,"rb") != 0){
				printf("No such file\n");
				continue;
			}
			if(SendBitFile(file)){
				printf("%s SENT SUCCESSFULLY!\n", input);
				fclose(file);
				return;
			}else{
				printf("ERROR SENDING %s\n", input);
				fclose(file);
			}
		}
	}
}

//Sends a bitfile to the USB device
bool SendBitFile(FILE* file){
	FT_STATUS usbStatus;
	FT_HANDLE usbHandle;

	//opens the only USB device attached to the computer
	usbStatus = FT_Open(0, &usbHandle);

	//if the device opened properly we continue, otherwise we give the error code and abort
	if(usbStatus == FT_OK)
		printf("USB Interface Opened Successfully!\n");
	else{
		printf("ERROR opening USB!  Code %u.\n", usbStatus);
		return false;
	}

	
	DWORD written;
	int totalWritten = 0;
	
	//the 1 means that we will send data 1 byte at a time.  If your 
	//data can be grouped into larger chunks, that would be more efficient.
	unsigned char data[1];
	
	//until the end of time...
	while(1){		
		//for each byte in our data array (our array is only one character wide)
		for(int i = 0; i < 1; i++){
			data[i] = fgetc(file);		//read the character from the file
			if(feof(file)) break;		//if we reached the end of our file then get out of here
			else printf("%i ", (unsigned int)data[i]); //otherwise print the character we just got for debugging
		}

		//We made it to the end of the file, so let's bail
		if(feof(file)){
			printf("   End of bit stream reached.\n");
			FT_Close(usbHandle);	//be sure to close the device
			return true;			//let whoever called us know it was a success
		}

		//this means: write 1 byte of the contents of data to the device in usbHandle,
		//and store the number of bytes that were successfully written to written
		usbStatus = FT_Write(usbHandle,data,1,&written);

		//Let the user know how many total bytes have been written.
		totalWritten += written;
		printf("   %u total bytes written\n", totalWritten);
		
		//if we didn't write as many bytes as we expected to, break out of the loop
		if(written != 1){
			printf("ERROR! Only %u of 1 bytes written successfully.  Aborting...\n", written);
			FT_Close(usbHandle);	//close the device
			return false;			//let the caller know we ran into issues
		}

		//if our device is having issus of any sort, display the error code and break
		if(usbStatus != FT_OK){
			printf("ERROR writing data!  Code %u.  Aborting...\n", usbStatus);
			FT_Close(usbHandle);	//close the device
			return false;			//let the caller know we ran into issues
		}
	}
}

//Sends a bitfile to the USB device
void HandEnterBytes(){
	FT_STATUS usbStatus;
	FT_HANDLE usbHandle;

	//opens the only USB device attached to the computer
	usbStatus = FT_Open(0, &usbHandle);

	//if the device opened properly we continue, otherwise we give the error code and abort
	if(usbStatus == FT_OK)
		printf("USB Interface Opened Successfully!\n");
	else{
		printf("ERROR opening USB!  Code %u.\n", usbStatus);
		return;
	}

	DWORD written;
	int totalWritten;
	unsigned char data[1];
	char input[3];
	
	//until the end of time...
	while(1){
		//get user input
		while(1){
			//give the user something to work with
			printf("Enter a number between 0 and 255 (Q to quit): ");
			scanf_s("%s", &input, 3);
		
			//quit if he wants
			if(strcmp(input,"Q") == 0){
				FT_Close(usbHandle);	//close the device
				return;
			}else{
				long byte = atol(input);
				if( (byte<0) || (byte > 255) ){
					printf("Invalid entry\n");
					//we don't loop, so we'll prompt for input again
				}else{
					data[0] = (unsigned char)byte;
					break;	//we've got valud data, so we can continue
				}
			}
		}

		//this means: write 1 byte of the contents of data to the device in usbHandle,
		//and store the number of bytes that were successfully written to written
		usbStatus = FT_Write(usbHandle,data,1,&written);

		//Let the user know how many total bytes have been written.
		totalWritten += written;
		printf("   %u total bytes written\n", totalWritten);
		
		//if we didn't write as many bytes as we expected to, break out of the loop
		if(written != 1){
			printf("ERROR! Only %u of 1 bytes written successfully.  Aborting...\n", written);
			FT_Close(usbHandle);	//close the device
			return;					//bail
		}

		//if our device is having issus of any sort, display the error code and break
		if(usbStatus != FT_OK){
			printf("ERROR writing data!  Code %u.  Aborting...\n", usbStatus);
			FT_Close(usbHandle);	//close the device
			return;					//bail
		}
	}
}