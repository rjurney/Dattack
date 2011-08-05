/*
Copyright 2008-2010 Gephi
Authors : Eduardo Ramos <eduramiba@gmail.com>
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
package org.gephi.datalab.plugin.manipulators.nodes.ui;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import net.miginfocom.swing.MigLayout;
import org.gephi.data.attributes.api.AttributeColumn;
import org.gephi.datalab.api.DataLaboratoryHelper;
import org.gephi.datalab.plugin.manipulators.nodes.MergeNodes;
import org.gephi.datalab.spi.DialogControls;
import org.gephi.datalab.spi.Manipulator;
import org.gephi.datalab.spi.ManipulatorUI;
import org.gephi.datalab.spi.rows.merge.AttributeRowsMergeStrategy;
import org.gephi.graph.api.Attributes;
import org.gephi.graph.api.Node;
import org.gephi.ui.components.richtooltip.RichTooltip;
import org.openide.util.ImageUtilities;
import org.openide.util.NbBundle;

public final class MergeNodesUI extends JPanel implements ManipulatorUI {

    private static final ImageIcon CONFIG_BUTTONS_ICON = ImageUtilities.loadImageIcon("org/gephi/datalab/plugin/manipulators/resources/gear.png", true);
    private static final ImageIcon INFO_LABELS_ICON = ImageUtilities.loadImageIcon("org/gephi/datalab/plugin/manipulators/resources/information.png", true);
    private MergeNodes manipulator;
    private JCheckBox deleteMergedNodesCheckBox;
    private JComboBox nodesComboBox;
    private Node[] nodes;
    private Attributes[] rows;
    private StrategyComboBox[] strategiesComboBoxes;
    private StrategyConfigurationButton[] strategiesConfigurationButtons;

    /** Creates new form ImportCSVUIVisualPanel2 */
    public MergeNodesUI() {
        initComponents();
    }

    public void setup(Manipulator m, DialogControls dialogControls) {
        manipulator = (MergeNodes) m;
        loadSettings();
    }

    public void unSetup() {
        manipulator.setDeleteMergedNodes(deleteMergedNodesCheckBox.isSelected());
        manipulator.setSelectedNode(nodes[nodesComboBox.getSelectedIndex()]);
        AttributeRowsMergeStrategy[] chosenStrategies = new AttributeRowsMergeStrategy[strategiesComboBoxes.length];
        for (int i = 0; i < strategiesComboBoxes.length; i++) {
            chosenStrategies[i] = strategiesComboBoxes[i].getSelectedItem() != null ? ((StrategyWrapper) strategiesComboBoxes[i].getSelectedItem()).getStrategy() : null;
        }
        manipulator.setMergeStrategies(chosenStrategies);
    }

    public String getDisplayName() {
        return manipulator.getName();
    }

    public JPanel getSettingsPanel() {
        return this;
    }

    public boolean isModal() {
        return true;
    }

    public void loadSettings() {
        JPanel settingsPanel = new JPanel();
        settingsPanel.setLayout(new MigLayout("fillx"));
        loadDescription(settingsPanel);
        loadDeleteMergedNodesCheckBox(settingsPanel);
        loadSelectedRow(settingsPanel);
        loadColumnsStrategies(settingsPanel);
        scroll.setViewportView(settingsPanel);
    }

    private void loadColumnsStrategies(JPanel settingsPanel) {
        AttributeColumn[] columns = manipulator.getColumns();
        //Prepare node rows:
        rows = new Attributes[nodes.length];
        for (int i = 0; i < nodes.length; i++) {
            rows[i] = nodes[i].getAttributes();
        }

        strategiesConfigurationButtons = new StrategyConfigurationButton[columns.length];
        strategiesComboBoxes = new StrategyComboBox[columns.length];
        for (int i = 0; i < columns.length; i++) {
            //Strategy information label:
            StrategyInfoLabel infoLabel = new StrategyInfoLabel(i);

            //Strategy configuration button:
            strategiesConfigurationButtons[i] = new StrategyConfigurationButton(i);

            //Strategy selection:
            StrategyComboBox strategyComboBox = new StrategyComboBox(strategiesConfigurationButtons[i],infoLabel);
            strategiesComboBoxes[i] = strategyComboBox;
            for (AttributeRowsMergeStrategy strategy : getColumnAvailableStrategies(columns[i])) {
                strategyComboBox.addItem(new StrategyWrapper(strategy));
            }
            strategyComboBox.refresh();

            settingsPanel.add(new JLabel(columns[i].getTitle() + ": "), "wrap");

            settingsPanel.add(infoLabel, "split 3");
            settingsPanel.add(strategiesConfigurationButtons[i]);
            settingsPanel.add(strategyComboBox, "growx, wrap 15px");

        }
    }

    private List<AttributeRowsMergeStrategy> getColumnAvailableStrategies(AttributeColumn column) {
        ArrayList<AttributeRowsMergeStrategy> availableStrategies = new ArrayList<AttributeRowsMergeStrategy>();
        for (AttributeRowsMergeStrategy strategy : DataLaboratoryHelper.getDefault().getAttributeRowsMergeStrategies()) {
            strategy.setup(rows, manipulator.getSelectedNode().getAttributes(), column);
            if (strategy.canExecute()) {
                availableStrategies.add(strategy);
            }
        }
        return availableStrategies;
    }

    private void loadDescription(JPanel settingsPanel) {
        JLabel descriptionLabel = new JLabel();
        descriptionLabel.setText(getMessage("MergeNodesUI.description"));
        settingsPanel.add(descriptionLabel, "wrap 25px");
    }

    private void loadDeleteMergedNodesCheckBox(JPanel settingsPanel) {
        deleteMergedNodesCheckBox = new JCheckBox(getMessage("MergeNodesUI.deleteMergedNodesText"), manipulator.isDeleteMergedNodes());
        settingsPanel.add(deleteMergedNodesCheckBox, "wrap 25px");
    }

    private void loadSelectedRow(JPanel settingsPanel) {
        JLabel selectedRowLabel = new JLabel();
        selectedRowLabel.setText(getMessage("MergeNodesUI.selectedRowText"));
        settingsPanel.add(selectedRowLabel, "wrap");
        nodesComboBox = new JComboBox();

        //Prepare selected node combo box with nodes data:
        nodes = manipulator.getNodes();
        Node selectedNode = manipulator.getSelectedNode();

        for (int i = 0; i < nodes.length; i++) {
            nodesComboBox.addItem(nodes[i].getId() + " - " + nodes[i].getNodeData().getLabel());
            if (nodes[i] == selectedNode) {
                nodesComboBox.setSelectedIndex(i);
            }
        }
        settingsPanel.add(nodesComboBox, "growx, wrap 25px");
    }

    private String getMessage(String resName) {
        return NbBundle.getMessage(MergeNodesUI.class, resName);
    }

    private AttributeRowsMergeStrategy getStrategy(int strategyIndex) {
        if (strategiesComboBoxes[strategyIndex] != null) {
            StrategyWrapper sw = (StrategyWrapper) strategiesComboBoxes[strategyIndex].getSelectedItem();
            if (sw != null) {
                return sw.getStrategy();
            }
        }
        return null;
    }

    class StrategyConfigurationButton extends JButton implements ActionListener {

        private int strategyIndex;

        public StrategyConfigurationButton(int strategyIndex) {
            this.strategyIndex = strategyIndex;
            setIcon(CONFIG_BUTTONS_ICON);
            setToolTipText(getMessage("MergeNodesUI.configurationText"));
            addActionListener(this);
        }

        public void refreshEnabledState() {
            AttributeRowsMergeStrategy strategy = getStrategy(strategyIndex);
            setEnabled(strategy != null && strategy.getUI() != null);//Has strategy and the strategy has UI
        }

        public void actionPerformed(ActionEvent e) {
            DataLaboratoryHelper.getDefault().showAttributeRowsMergeStrategyUIDialog(getStrategy(strategyIndex));
        }
    }

    class StrategyComboBox extends JComboBox implements ActionListener {
        private StrategyConfigurationButton button;
        private StrategyInfoLabel infoLabel;

        public StrategyComboBox(StrategyConfigurationButton button, StrategyInfoLabel infoLabel) {
            this.button = button;
            this.infoLabel = infoLabel;
            this.addActionListener(this);
        }
        
        public void refresh() {
            button.refreshEnabledState();
            infoLabel.refreshEnabledState();
        }

        @Override
        public void actionPerformed(ActionEvent e) {
            refresh();
        }
    }

    class StrategyInfoLabel extends JLabel {

        private int strategyIndex;

        public StrategyInfoLabel(int strategyIndex) {
            this.strategyIndex = strategyIndex;
            setIcon(INFO_LABELS_ICON);
            prepareRichTooltip();
        }

        public void refreshEnabledState() {
            AttributeRowsMergeStrategy strategy = getStrategy(strategyIndex);
            setEnabled(strategy != null && strategy.getDescription() != null && !strategy.getDescription().isEmpty());
        }

        private void prepareRichTooltip() {
            addMouseListener(new MouseAdapter() {

                RichTooltip richTooltip;

                @Override
                public void mouseEntered(MouseEvent e) {
                    if (isEnabled()) {
                        richTooltip = buildTooltip(getStrategy(strategyIndex));
                    }

                    if (richTooltip != null) {
                        richTooltip.showTooltip(StrategyInfoLabel.this);
                    }
                }

                @Override
                public void mouseExited(MouseEvent e) {
                    if (richTooltip != null) {
                        richTooltip.hideTooltip();
                        richTooltip = null;
                    }
                }

                private RichTooltip buildTooltip(AttributeRowsMergeStrategy strategy) {
                    if (strategy.getDescription() != null && !strategy.getDescription().isEmpty()) {
                        RichTooltip tooltip = new RichTooltip(strategy.getName(), strategy.getDescription());
                        if (strategy.getIcon() != null) {
                            tooltip.setMainImage(ImageUtilities.icon2Image(strategy.getIcon()));
                        }
                        return tooltip;
                    } else {
                        return null;
                    }
                }
            });
        }
    }

    class StrategyWrapper {

        private AttributeRowsMergeStrategy strategy;

        public StrategyWrapper(AttributeRowsMergeStrategy strategy) {
            this.strategy = strategy;
        }

        @Override
        public String toString() {
            return strategy.getName();
        }

        public AttributeRowsMergeStrategy getStrategy() {
            return strategy;
        }
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        scroll = new javax.swing.JScrollPane();

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(scroll, javax.swing.GroupLayout.DEFAULT_SIZE, 594, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(scroll, javax.swing.GroupLayout.DEFAULT_SIZE, 320, Short.MAX_VALUE)
        );
    }// </editor-fold>//GEN-END:initComponents
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JScrollPane scroll;
    // End of variables declaration//GEN-END:variables
}
