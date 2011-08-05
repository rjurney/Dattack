/*
Copyright 2008-2010 Gephi
Authors : Martin Škurla
Website : http://www.gephi.org

This file is part of Gephi.

Gephi is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Gephi is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with Gephi.  If not, see <http://www.gnu.org/licenses/>.
*/

package org.gephi.data.attributes.type;

import org.junit.Test;
import static org.junit.Assert.*;

/**
 * @author Martin Škurla
 */
public class StringListTest {

    @Test
    public void testCreatingListFromStringWithDefaultSeparator() {
        StringList list = new StringList("aa,bb;cc");
        assertEquals(list.size(), 3);
    }

    @Test
    public void testCreatingListFromStringWithGivenSeparator() {
        StringList list = new StringList("aa/bb/cc", "/");
        assertEquals(list.size(), 3);
    }

    @Test
    public void testCreatingListFromStringArray() {
        StringList list = new StringList(new String[] {"aa", "bb", "cc"});
        assertEquals(list.size(), 3);
    }

    @Test
    public void testCreatingListFromCharArray() {
        StringList list = new StringList(new char[] {'a', 'b', 'c'});
        assertEquals(list.size(), 3);
    }

    @Test
    public void testCreatingListFromEmptyStringArray() {
        StringList list = new StringList(new String[0]);
        assertEquals(list.size(), 0);
    }

    @Test
    public void testCreatingListFromEmptyCharArray() {
        StringList list = new StringList(new char[0]);
        assertEquals(list.size(), 0);
    }
}
