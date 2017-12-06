/*  =========================================================================
    fty_test - Manages discovery requests, provides feedback

    Copyright (C) 2014 - 2017 Eaton                                        
                                                                           
    This program is free software; you can redistribute it and/or modify   
    it under the terms of the GNU General Public License as published by   
    the Free Software Foundation; either version 2 of the License, or      
    (at your option) any later version.                                    
                                                                           
    This program is distributed in the hope that it will be useful,        
    but WITHOUT ANY WARRANTY; without even the implied warranty of         
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          
    GNU General Public License for more details.                           
                                                                           
    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.            
    =========================================================================
*/

/*
@header
    fty_test - Manages discovery requests, provides feedback
@discuss
@end
*/

#include "fty_test_classes.h"

//  Structure of our class

struct _fty_test_t {
    int filler;     //  Declare class properties here
};

void
fty_lib_test_print () {
    std::cout << "This library work. Great !\n";
}


//  --------------------------------------------------------------------------
//  Self test of this class

void
fty_test_test (bool verbose)
{
    printf (" * fty_test: ");

    //  @selftest
    //  Simple create/destroy test
    //  @end
    printf ("OK\n");
}
