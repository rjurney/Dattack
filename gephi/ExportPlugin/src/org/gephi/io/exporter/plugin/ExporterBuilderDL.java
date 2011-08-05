/*
Copyright 2008-2011 Gephi
Authors : Taras Klaskovsky <megaterik@gmail.com>
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
package org.gephi.io.exporter.plugin;

import org.gephi.io.exporter.api.FileType;
import org.gephi.io.exporter.spi.GraphExporter;
import org.gephi.io.exporter.spi.GraphFileExporterBuilder;
import org.openide.util.NbBundle;
import org.openide.util.lookup.ServiceProvider;

@ServiceProvider(service = GraphFileExporterBuilder.class)
public class ExporterBuilderDL implements GraphFileExporterBuilder 
{

    @Override
    public GraphExporter buildExporter() {
       return new ExporterDL();
    }

    @Override
    public FileType[] getFileTypes() {
        return new FileType[]{new FileType(".dl", NbBundle.getMessage(ExporterBuilderCSV.class, "fileType_DL_Name"))};
    }

    @Override
    public String getName() {
        return "DL";
    }
    
}
